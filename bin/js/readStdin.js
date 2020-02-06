/**
 * @returns {Promise<string>}
 */
export function readStdin() {
  return new Promise(resolve => {
    let buffer = ""
    if (process.stdin.isTTY) {
      resolve(buffer)
      return
    }
    process.stdin.setEncoding("utf8")
    process.stdin.on("readable", () => {
      let chunk
      while ((chunk = process.stdin.read())) {
        buffer += chunk
      }
    })
    process.stdin.on("end", () => {
      resolve(buffer)
    })
  })
}
