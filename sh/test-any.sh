#!/usr/bin/env node
const child_process = require('child_process')

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

// test share env
async function testShareEnv() {
  await exec('echo "SP_VERSION=1.0.1" >> $GITHUB_ENV')
}

async function main() {
  await testShareEnv()
}

main()
