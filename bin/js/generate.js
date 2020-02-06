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
      "Ok" in a ? resolve(a.Ok[0]) : reject(a.Err[0])
    }

    main.Elm.Main.init({ flags }).ports.done.subscribe(callback)
  })
}
