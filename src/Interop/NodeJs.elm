module Interop.NodeJs exposing (..)

import Interop.JsCode as JsCode
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)
import Utils.Task_ as Task_


{-| To get program arguments.
<https://stackoverflow.com/questions/9725675/is-there-a-standard-format-for-command-line-shell-help-text>
-}
getArguments : Task String (List String)
getArguments =
    JsCode.eval "process.argv"
        |> Task_.andThenDecode (Decode.list Decode.string)


{-| To get stdin.
-}
getStdin : Task String (Maybe String)
getStdin =
    JsCode.eval "process.stdin.isTTY ? null : require('fs/promises').readFile(0, 'utf8')"
        |> Task_.andThenDecode (Decode.nullable Decode.string)



--


{-| To call console.log function.
-}
consoleLog : String -> Task String ()
consoleLog _ =
    JsCode.eval "console.log(_v0)"
        |> Task_.andThenDecode (Decode.succeed ())


{-| To call console.error function.
-}
consoleError : String -> Task String ()
consoleError _ =
    JsCode.eval "console.error(_v0)"
        |> Task_.andThenDecode (Decode.succeed ())


{-| To kill process with exit code.
-}
processExit : Int -> Task String ()
processExit _ =
    JsCode.eval "process.exit(_v0)"
        |> Task_.andThenDecode (Decode.succeed ())



--


{-| To get \_\_filename.
-}
filename__ : Task String String
filename__ =
    JsCode.eval "__filename"
        |> Task_.andThenDecode Decode.string


{-| To get \_\_dirname.
-}
dirname__ : Task String String
dirname__ =
    JsCode.eval "__dirname"
        |> Task_.andThenDecode Decode.string


{-| To get real path.
-}
realPath : String -> Task String String
realPath _ =
    JsCode.eval "require('fs/promises').realpath(_v0, 'utf8')"
        |> Task_.andThenDecode Decode.string



--


{-| To create directory recursively.
-}
mkDir : String -> Task String ()
mkDir _ =
    JsCode.eval "require('fs/promises').mkdir(_v0, { recursive: true })"
        |> Task_.andThenDecode (Decode.succeed ())


{-| To read file.
-}
readFile : String -> Task String String
readFile _ =
    JsCode.eval "require('fs/promises').readFile(_v0, 'utf8')"
        |> Task_.andThenDecode Decode.string


{-| To write file.
-}
writeFile : String -> String -> Task String ()
writeFile _ _ =
    JsCode.eval "require('fs/promises').writeFile(_v0, _v1)"
        |> Task_.andThenDecode (Decode.succeed ())


{-| To copy file.
-}
copyFile : String -> String -> Task String ()
copyFile _ _ =
    JsCode.eval "require('fs/promises').copyFile(_v0, _v1)"
        |> Task_.andThenDecode (Decode.succeed ())
