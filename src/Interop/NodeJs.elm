module Interop.NodeJs exposing (..)

import Interop.JavaScript as JavaScript
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


{-| Get program arguments.
<https://stackoverflow.com/questions/9725675/is-there-a-standard-format-for-command-line-shell-help-text>
-}
arguments : Task JavaScript.Error (List String)
arguments =
    JavaScript.run "process.argv"
        |> JavaScript.decode (Decode.list Decode.string)



--


log : String -> Task JavaScript.Error ()
log _ =
    JavaScript.run "console.log(_v0)"
        |> JavaScript.decode (Decode.succeed ())


logError : String -> Task JavaScript.Error ()
logError _ =
    JavaScript.run "console.error(_v0)"
        |> JavaScript.decode (Decode.succeed ())


exit : Int -> Task JavaScript.Error ()
exit _ =
    JavaScript.run "process.exit(_v0)"
        |> JavaScript.decode (Decode.succeed ())



--


scriptDirname : Task JavaScript.Error String
scriptDirname =
    JavaScript.run "__dirname"
        |> JavaScript.decode Decode.string


fileRealPath : String -> Task JavaScript.Error String
fileRealPath _ =
    JavaScript.run "await require('fs/promises').realpath(_v0, 'utf8')"
        |> JavaScript.decode Decode.string



--


createDirectory : String -> Task JavaScript.Error ()
createDirectory _ =
    JavaScript.run "await require('fs/promises').mkdir(_v0, { recursive: true })"
        |> JavaScript.decode (Decode.succeed ())


readFile : String -> Task JavaScript.Error String
readFile _ =
    JavaScript.run "await require('fs/promises').readFile(_v0, 'utf8')"
        |> JavaScript.decode Decode.string


writeFile : String -> String -> Task JavaScript.Error ()
writeFile _ _ =
    JavaScript.run "await require('fs/promises').writeFile(_v0, _v1)"
        |> JavaScript.decode (Decode.succeed ())


copyFile : String -> String -> Task JavaScript.Error ()
copyFile _ _ =
    JavaScript.run "await require('fs/promises').copyFile(_v0, _v1)"
        |> JavaScript.decode (Decode.succeed ())
