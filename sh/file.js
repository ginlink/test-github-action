#!/usr/bin/env node

const fs = require('fs')
const path = require('path')

// TODO用流进行操作

function validVersion(version) {
  const reg = /(\d{1,3}\.){2}\d{1,3}/

  if (!reg.test(version)) {
    throw new Error(`except version, like 1.0.0, but got ${version}`)
  }

  return version
}

function removeLastLineData(filepath) {
  return new Promise((resolve, reject) => {
    let failedResult = {
      success: false,
      data: undefined
    }

    try {

      const data = fs.readFileSync(filepath, { encoding: 'utf-8' })

      if (!data || data === '\n') {
        if (data === '\n') {
          fs.writeFileSync(filepath, '')
        }

        resolve({
          success: true,
          data: undefined
        })
      }

      const arrLines = data.split('\n')

      let current = undefined

      // handle last ''
      while (arrLines[arrLines.length - 1] === '') arrLines.pop()

      let hasValueCurrent = undefined
      while (true) {
        current = arrLines.pop()

        // for unique compare
        if (current) {
          hasValueCurrent = current
        }

        // skip ''
        if (arrLines[arrLines.length - 1] === '') {
          continue
        }

        // no left element
        if (current === undefined) {
          resolve({
            success: true,
            data: undefined
          })
          break
        }

        // unique
        if (hasValueCurrent !== arrLines[arrLines.length - 1]) {
          break
        }
      }

      const newData = arrLines.length ? arrLines.join('\n') : ''

      fs.writeFileSync(filepath, newData)

      const lastVersion = arrLines[arrLines.length - 1]

      // full success
      resolve({
        success: true,
        data: lastVersion ? validVersion(lastVersion) : undefined,
      })
    } catch (err) {
      console.log('[](err):', err)
      reject(failedResult)
    }
  })

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

async function main() {

  const filepath = path.join(__dirname, 'version_history.txt')

  // console.log('[]:', await addLastLine('1.0.3', filepath))

  const result = await removeLastLineData(filepath)
  console.log('[removeLastLineData](result):', result)
}

main()