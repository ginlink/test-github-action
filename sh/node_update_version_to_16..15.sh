#!/usr/bin/env node
const child_process = require('child_process');
const path = require('path');
const fs = require('fs');
const env = process.env

console.log('hello, i am running!')
// console.log(`the env is ${process.env}`)
console.log(`the tag version is ${process.env.RELEASE_VERSION}`)

const currentTag = env.RELEASE_VERSION
const REMOTE_HOST = env.REMOTE_HOST
const REMOTE_NAME = env.REMOTE_NAME
const VERSION_NAME = 'version_history.txt'
const loginFilepath = path.join(__dirname, 'login_ssh.sh')
const versionFilepath = path.join(__dirname, 'version', VERSION_NAME)
const versionFilepathRemote = `~/sh/version/${VERSION_NAME}`

function exec(command) {
  return new Promise((resolve, reject) => {
    const child = child_process.exec(command, (error, stdout, stderr) => {
      if (error) {
        reject({ error, child })
      }

      resolve({
        stdout, stderr, child
      })

    })
  })
}

function execFile(filepath, options) {
  options = options || []

  return new Promise((resolve, reject) => {
    const child = child_process.execFile(filepath, options, (error, stdout, stderr) => {
      if (error) {
        reject({ error, child })
      }

      resolve({
        error, stdout, stderr, child
      })
    });
  })

}

function validVersion(version) {
  const reg = /(\d{1,3}\.){2}\d{1,3}/

  if (!reg.test(version)) {
    throw new Error(`except version, like 1.0.0, but got ${version}`)
  }

  return version
}

function addLastLine(version, filepath) {

  return new Promise((resolve, reject) => {

    validVersion(version)

    try {
      fs.writeFileSync(filepath, `\n${version}`, {
        flag: 'a+'
      })
      resolve(true)
    } catch (err) {
      console.log('[](err):', err)

      reject(err)
    }
  })

}

async function actionMkdir(dirPath, dirs) {
  if (!dirPath || !dirs) {
    throw new Error('expect dirPath and dirs, but got undefined')
  }

  const combinedDirs = dirs.map((item) => path.join(dirPath, item)).join(' ')

  try {
    await exec(`mkdir ${combinedDirs}`)
  } catch (err) {
  }
}

async function actionLoginSSH() {
  const { stdout } = await execFile(loginFilepath)

  console.log('[login](stdout):', stdout)
}

async function actionScpRemoteFile() {
  try {
    await exec(`scp ${REMOTE_NAME}@${REMOTE_HOST}:${versionFilepathRemote} ${versionFilepath}`)
  } catch (err) {
    console.log('[actionScpRemoteFile](err):', err.error)
  }
}

async function actionUpdateVersion(tag) {
  await addLastLine(tag, versionFilepath)

  console.log('[success](update-version):', tag)
}

async function actionScp2Remote() {
  try {
    await exec(`scp ${versionFilepath} ${REMOTE_NAME}@${REMOTE_HOST}:${versionFilepathRemote}`)
  } catch (err) {
    console.log('[actionScp2Remote](err):', err.error)
  }
}

async function main() {
  if (!currentTag) return console.log('[main](no tag):',)

  try {
    await actionMkdir(__dirname, ['version', 'docker'])

    await actionLoginSSH()
    await actionScpRemoteFile()
    await actionUpdateVersion(currentTag)
    await actionScp2Remote()
  } catch (err) {
    console.log('[](err):', err)
  }
}

main()