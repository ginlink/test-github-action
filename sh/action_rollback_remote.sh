#!/root/.nvm/versions/node/v14.18.2/bin/node

const child_process = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('node_remote_deploy, i am running');

const VERSION_NAME = 'version_history.txt';
const imageName = 'ginlink\\/test-rollback'
const versionFilepath = path.join(__dirname, 'version', VERSION_NAME);

const containerName = imageName.split('/')[1]
const dockerComposeFilepath = path.join(
  __dirname,
  'docker-compose.yml',
)
const dockerComposeExamplelFilepath = path.join(
  __dirname,
  'docker-compose-example.yml',
)

const dockerRemove = `docker rm -f ${containerName}`;
const dockerPull = `docker-compose  -f  docker-compose-dev.yml pull`;
const dockerDown = `docker-compose -f docker-compose-dev.yml down`;
const dockerUp = `docker-compose -f docker-compose-dev.yml up -d`;

console.log('[]:', versionFilepath);
console.log('[]:', dockerComposeFilepath);

// TODO用流进行操作

function exec(command) {
  return new Promise((resolve, reject) => {
    const child = child_process.exec(command, (error, stdout, stderr) => {
      if (error) {
        reject({ error, child });
      }

      resolve({
        stdout,
        stderr,
        child,
      });
    });
  });
}

function validVersion(version) {
  const reg = /(\d{1,3}\.){2}\d{1,3}/;

  if (!reg.test(version)) {
    throw new Error(`except version, like 1.0.0, but got ${version}`);
  }

  return version;
}

function removeLastLineData(filepath) {
  return new Promise((resolve, reject) => {
    let failedResult = {
      success: false,
      data: undefined,
    };

    try {
      const data = fs.readFileSync(filepath, { encoding: 'utf-8' });

      if (!data || data === '\n') {
        if (data === '\n') {
          fs.writeFileSync(filepath, '');
        }

        resolve({
          success: true,
          data: undefined,
        });
      }

      const arrLines = data.split('\n');

      let current = undefined;

      // handle last ''
      while (arrLines[arrLines.length - 1] === '') arrLines.pop();

      let hasValueCurrent = undefined;
      while (true) {
        current = arrLines.pop();

        // for unique compare
        if (current) {
          hasValueCurrent = current;
        }

        // skip ''
        if (arrLines[arrLines.length - 1] === '') {
          continue;
        }

        // no left element
        if (current === undefined) {
          resolve({
            success: true,
            data: undefined,
          });
          break;
        }

        // unique
        if (hasValueCurrent !== arrLines[arrLines.length - 1]) {
          break;
        }
      }

      let newData = arrLines.length ? arrLines.join('\n') : '';
      newData += '\n' //last line append a \n

      fs.writeFileSync(filepath, newData);

      const lastVersion = arrLines[arrLines.length - 2];

      // full success
      resolve({
        success: true,
        data: lastVersion ? validVersion(lastVersion) : undefined,
      });
    } catch (err) {
      console.log('[](err):', err);
      reject(failedResult);
    }
  });
}

function getLatestVersion() {
  return new Promise((resolve, reject) => {
    try {
      const data = fs.readFileSync(versionFilepath, { encoding: 'utf-8' });

      if (!data) {
        resolve(undefined);
      }

      const arrLines = data.split('\n');

      resolve(arrLines[arrLines.length - 2]);
    } catch (err) {
      reject(err);
    }
  });
}


async function actionHandleComposeFile(tag) {
  if (!tag) {
    throw new Error('[actionHandleStopFile](err):', 'no tag');
  }

  const targetImageName = `${imageName}:${tag}`;

  try {
    await exec(`cp ${dockerComposeExamplelFilepath} ${dockerComposeFilepath}`)
  } catch (err) { }

  await exec(
    `sed -i "s/example\\/example-image:tag/${targetImageName}/g" ${dockerComposeFilepath}`,
  );
  await exec(
    `sed -i "s/example_container_name/${containerName}/g" ${dockerComposeFilepath}`,
  );
}

async function actionDockerCompose(preTag, latestTag) {
  await actionHandleComposeFile(preTag);
  await exec(dockerPull);

  await actionHandleComposeFile(latestTag);
  await exec(dockerRemove);
  await exec(dockerDown);

  await actionHandleComposeFile(preTag);
  await exec(dockerUp);
}

async function main() {
  const latestTag = await getLatestVersion();

  if (!validVersion(latestTag)) {
    throw new Error('[removeLastLineData](err):', 'version数据异常');
  }

  const { success, data: preTag } = await removeLastLineData(versionFilepath);

  if (!success || !preTag) {
    throw new Error('[removeLastLineData](err):', 'version数据异常');
  }


  console.log('[]:', success, latestTag, preTag)
  // process.exit(0)
  await actionDockerCompose(preTag, latestTag);
}

main();
