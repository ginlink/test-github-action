#!/root/.nvm/versions/node/v14.18.2/bin/node

const child_process = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('node_remote_deploy, i am running');

const VERSION_NAME = 'version_history.txt';
const versionFilepath = path.join(__dirname, 'version', VERSION_NAME);
const dockerComposeFilepath = path.join(
  __dirname,
  'docker',
  'docker-compose.yml',
)
const dockerComposeExamplelFilepath = path.join(
  __dirname,
  'docker',
  'docker-compose-example.yml',
)

const imageName = 'ginlink\\/test-rollback';

const dockerPull = `docker-compose  -f  ${dockerComposeFilepath} pull`;
const dockerDown = `docker-compose -f ${dockerComposeFilepath} down`;
const dockerUp = `docker-compose -f ${dockerComposeFilepath} up -d`;

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

      const newData = arrLines.length ? arrLines.join('\n') : '';

      fs.writeFileSync(filepath, newData);

      const lastVersion = arrLines[arrLines.length - 1];

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
      const version = arrLines[arrLines.length - 2]
      console.log('[](read-version):', version, arrLines)

      resolve(version ? version : undefined);
    } catch (err) {
      reject(err);
    }
  });
}

async function actionHandleComposeFile(tag, imageName) {
  if (!tag) {
    throw new Error('[actionHandleComposeFile](err):', 'no tag');
  }

  // const targetImageName = `ginlink/test-rollback:${tag}`;
  const targetImageName = `${imageName}:${tag}`;
  const containerName = imageName.split('/')[1]

  console.log('[](imageName):', targetImageName)

  try {
    await exec(`cp ${dockerComposeExamplelFilepath} ${dockerComposeFilepath}`)
    await exec(`docker rm -f ${containerName}`)
  } catch (err) { }

  await exec(
    `sed -i "s/example\\/example-image:tag/${targetImageName}/g" ${dockerComposeFilepath}`,
  );
  await exec(
    `sed -i "s/example_container_name/${containerName}/g" ${dockerComposeFilepath}`,
  );
}

async function actionDockerCompose() {
  await exec(dockerPull);
  await exec(dockerDown);
  await exec(dockerUp);
}

async function main() {
  try {
    const tag = await getLatestVersion();
    console.log('[](latest-tag):', tag)

    await actionHandleComposeFile(tag, imageName);

    await actionDockerCompose();
  } catch (err) {
    console.log('[node_remote_deploy](err):', err);
  }
}

main();
