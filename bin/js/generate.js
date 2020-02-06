// @ts-ignore
import main from "../../dist/main.cjs"

/**
 * @param {string} flags
 * @returns {Promise<[string, string, string]>}
 */
export function generate(flags) {
  return new Promise((resolve, reject) => {
    /**
     * @param {{ Ok: [[string, string, string]] } | { Err: [string] }} a
     */
    function callback(a) {
      if ("Ok" in a) {
        const [b] = a.Ok
        resolve(b)
      } else {
        const [b] = a.Err
        reject(b)
      }
    }

    main.Elm.Main.init({ flags }).ports.done.subscribe(callback)
  })
}
