#!/root/.nvm/versions/node/v14.18.2/bin/node

const child_process = require('child_process');
const fs = require('fs');
const path = require('path');

console.log('node_remote_deploy, i am running');

const imageName = 'ginlink\\/test-rollback'
const containerName = imageName.split('/')[1]

const versionFilepath = path.join(__dirname, 'version_history.txt');
const versionFilepathTmp = path.join(__dirname, 'version_history_tmp.txt');
const versionFilepathBak = path.join(__dirname, 'version_history_bak.txt');

const dockerComposeFilepathTmp = path.join(
  __dirname,
  'docker_compose_tmp.yml',
)
const dockerComposeExamplelFilepath = path.join(
  __dirname,
  'docker-compose-example.yml',
)

const dockerRemove = `docker rm -f ${containerName}`;
const dockerPull = `docker-compose  -f  ${dockerComposeFilepathTmp} pull`;
const dockerDown = `docker-compose -f ${dockerComposeFilepathTmp} down`;
const dockerUp = `docker-compose -f ${dockerComposeFilepathTmp} up -d`;

console.log('[]:', versionFilepath);
console.log('[]:', dockerComposeFilepathTmp);

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

function consumeVersion(filepath, isConsume) {
  isConsume = (isConsume === undefined) ? true : isConsume

  return new Promise((resolve, reject) => {

    try {
      const data = fs.readFileSync(filepath, { encoding: 'utf-8' });

      if (!data || data === '\n') {
        if (data === '\n') {
          fs.writeFileSync(filepath, '');
        }

        resolve(undefined);
      }

      const arrLines = data.split('\n');

      // skip ''
      while (arrLines[arrLines.length - 1] === '') arrLines.pop();

      let current = undefined;
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
          resolve(undefined);
          break;
        }

        // unique
        if (hasValueCurrent !== arrLines[arrLines.length - 1]) {
          break;
        }
      }

      if (!isConsume) {
        arrLines.push(current)
      }

      const lastVersion = arrLines[arrLines.length - 1];

      let newData = arrLines.length ? arrLines.join('\n') : '';
      newData += '\n' //last line append a \n

      fs.writeFileSync(filepath, newData);


      // full success
      resolve(lastVersion);
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
    await exec(`cp ${dockerComposeExamplelFilepath} ${dockerComposeFilepathTmp}`)
  } catch (err) { }

  await exec(
    `sed -i "s/example\\/example-image:tag/${targetImageName}/g" ${dockerComposeFilepathTmp}`,
  );
  await exec(
    `sed -i "s/example_container_name/${containerName}/g" ${dockerComposeFilepathTmp}`,
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
  try {
    // copy version file
    await exec(`cp ${versionFilepath} ${versionFilepathTmp}`)

    const latestTag = await consumeVersion(versionFilepathTmp, false)
    const preTag = await consumeVersion(versionFilepathTmp)

    if (!validVersion(latestTag) || !validVersion(preTag)) {
      throw new Error('[err]:', 'version数据异常');
    }

    console.log('[tag]:', latestTag, preTag)

    // stop and start
    await actionDockerCompose(preTag, latestTag);

    // bak
    await exec(`cp ${versionFilepath} ${versionFilepathBak}`)

    // version file take effect
    await exec(`cp ${versionFilepathTmp} ${versionFilepath}`)

    console.log('[success]: rollback',)
  } catch (err) {
    console.log('[err]:', err)

    // assign exit with 1, because node exit with 0 when exception happen
    process.exit(1)
  } finally {
    // remove tmp file
    await exec(`rm ${versionFilepathTmp} ${dockerComposeFilepathTmp}`)
  }
}

main();
