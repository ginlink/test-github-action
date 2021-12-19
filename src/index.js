#!/usr/bin/env node

const fs = require('fs')
const path = require('path')

// TODO用流进行操作

function removeLastLineData(filepath) {
  return new Promise((resolve, reject) => {
    let failedResult = {
      success: false,
      data: undefined
    }

    try {

      const data = fs.readFileSync(filepath, { encoding: 'utf-8' })

      if (!data || data == '\n') {
        if (data == '\n') {
          fs.writeFileSync(filepath, '')
        }

        resolve({
          success: true,
          data: undefined
        })
      }

      const arrLines = data.split('\n')

      let resultData = undefined

      while ((resultData = arrLines.pop()) === '') { }

      const newData = arrLines.length ? arrLines.join('\n') : ''

      fs.writeFileSync(filepath, newData)

      // full success
      resolve({
        success: true,
        data: resultData,
      })
    } catch (err) {
      console.log('[](err):', err)
      reject(failedResult)
    }
  })

}

function addLastLine(data, filepath) {

  return new Promise((resolve, reject) => {
    if (!data.match(/(\d{1,3}\.){2}\d{1,3}/)) {
      resolve(false)
    }

    try {
      fs.writeFileSync(filepath, `\n${data}`, {
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

  // console.log('[]:', await addLastLine('1.0.1', filepath))

  const result = await removeLastLineData(filepath)
  console.log('[removeLastLineData](result):', result)
}

main()