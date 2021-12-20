#!/usr/bin/env node

const child_process = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('node_remote_deploy, i am running');

const VERSION_NAME = 'version_history.txt';
const versionFilepath = path.join(__dirname, 'version', VERSION_NAME);
const dockerComposeFilepath = path.join(
  __dirname,
  '..',
  'docker-compose-dev.yml',
);
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

async function actionStopCurrent(tag) {
  if (!tag) {
    throw new Error('[actionHandleComposeFile](err):', 'no tag');
  }

  const targetImageName = `ginlink/test-rollback:${tag}`;

  await exec(
    `sed -i "s/example\\/example-image:tag/${targetImageName}/g" ${dockerComposeFilepath}`,
  );
  await exec(dockerDown);
}

async function actionHandleComposeFile(tag) {
  if (!tag) {
    throw new Error('[actionHandleComposeFile](err):', 'no tag');
  }

  const targetImageName = `ginlink/test-rollback:${tag}`;

  await exec(
    `sed -i "s/example\\/example-image:tag/${targetImageName}/g" ${dockerComposeFilepath}`,
  );
}

async function actionDockerCompose(tag) {
  await actionHandleComposeFile(tag);

  await exec(dockerPull);
  await exec(dockerDown);
  await exec(dockerUp);
}

async function main() {
  const latestTag = await getLatestVersion();

  if (!validVersion(latestTag)) {
    throw new Error('[removeLastLineData](err):', 'version数据异常');
  }

  const { success, data: tag } = await removeLastLineData(versionFilepath);

  if (!success || !tag) {
    throw new Error('[removeLastLineData](err):', 'version数据异常');
  }


  console.log('[]:', success, latestTag, tag)
  process.exit(0)
  await actionStopCurrent(latestTag);
  await actionDockerCompose(tag);
}

main();
