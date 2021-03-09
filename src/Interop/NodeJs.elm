module Interop.NodeJs exposing (..)

import Interop.JavaScript as JavaScript exposing (Exception)
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


{-| To get program arguments.
<https://stackoverflow.com/questions/9725675/is-there-a-standard-format-for-command-line-shell-help-text>
-}
getArguments : Task Exception (List String)
getArguments =
    JavaScript.run "process.argv"
        |> JavaScript.decode (Decode.list Decode.string)


{-| To get stdin.
-}
getStdin : Task Exception (Maybe String)
getStdin =
    JavaScript.run "await (process.stdin.isTTY ? null : require('fs/promises').readFile(0, 'utf8'))"
        |> JavaScript.decode (Decode.nullable Decode.string)



--


{-| To call console.log function.
-}
consoleLog : String -> Task Exception ()
consoleLog _ =
    JavaScript.run "console.log(_v0)"
        |> JavaScript.decode (Decode.succeed ())


{-| To call console.error function.
-}
consoleError : String -> Task Exception ()
consoleError _ =
    JavaScript.run "console.error(_v0)"
        |> JavaScript.decode (Decode.succeed ())


{-| To kill process with exit code.
-}
processExit : Int -> Task Exception ()
processExit _ =
    JavaScript.run "process.exit(_v0)"
        |> JavaScript.decode (Decode.succeed ())



--


{-| To get \_\_filename.
-}
filename__ : Task Exception String
filename__ =
    JavaScript.run "__filename"
        |> JavaScript.decode Decode.string


{-| To get \_\_dirname.
-}
dirname__ : Task Exception String
dirname__ =
    JavaScript.run "__dirname"
        |> JavaScript.decode Decode.string


{-| To get real path.
-}
realPath : String -> Task Exception String
realPath _ =
    JavaScript.run "await require('fs/promises').realpath(_v0, 'utf8')"
        |> JavaScript.decode Decode.string



--


{-| To create directory recursively.
-}
mkDir : String -> Task Exception ()
mkDir _ =
    JavaScript.run "await require('fs/promises').mkdir(_v0, { recursive: true })"
        |> JavaScript.decode (Decode.succeed ())


{-| To read file.
-}
readFile : String -> Task Exception String
readFile _ =
    JavaScript.run "await require('fs/promises').readFile(_v0, 'utf8')"
        |> JavaScript.decode Decode.string


{-| To write file.
-}
writeFile : String -> String -> Task Exception ()
writeFile _ _ =
    JavaScript.run "await require('fs/promises').writeFile(_v0, _v1)"
        |> JavaScript.decode (Decode.succeed ())


{-| To copy file.
-}
copyFile : String -> String -> Task Exception ()
copyFile _ _ =
    JavaScript.run "await require('fs/promises').copyFile(_v0, _v1)"
        |> JavaScript.decode (Decode.succeed ())
