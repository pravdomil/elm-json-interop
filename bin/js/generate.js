// @ts-ignore
import main from "../../dist/main.cjs"

/**
 * @param {string} flags
 * @returns {Promise<[string, string, string]>}
 */
export function generate(flags) {
  return new Promise((resolve, reject) => {
    /**
     * @param {{ Ok: [string, string, string] } | { Err: string }} a
     */
    function callback(a) {
      "Ok" in a ? resolve(a.Ok) : reject(a.Err)
    }

    main.Elm.Main.init({ flags }).ports.done.subscribe(callback)
  })
}
