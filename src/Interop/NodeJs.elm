module Interop.NodeJs exposing (..)

import Interop.JavaScript as JavaScript
import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


{-| To get program arguments.
<https://stackoverflow.com/questions/9725675/is-there-a-standard-format-for-command-line-shell-help-text>
-}
getArguments : Task JavaScript.Error (List String)
getArguments =
    JavaScript.run "process.argv"
        |> JavaScript.decode (Decode.list Decode.string)



--


{-| To call console.log function.
-}
consoleLog : String -> Task JavaScript.Error ()
consoleLog _ =
    JavaScript.run "console.log(_v0)"
        |> JavaScript.decode (Decode.succeed ())


{-| To call console.error function.
-}
consoleError : String -> Task JavaScript.Error ()
consoleError _ =
    JavaScript.run "console.error(_v0)"
        |> JavaScript.decode (Decode.succeed ())


{-| To kill process with exit code.
-}
processExit : Int -> Task JavaScript.Error ()
processExit _ =
    JavaScript.run "process.exit(_v0)"
        |> JavaScript.decode (Decode.succeed ())



--


{-| To get \_\_filename.
-}
filename__ : Task JavaScript.Error String
filename__ =
    JavaScript.run "__filename"
        |> JavaScript.decode Decode.string


{-| To get \_\_dirname.
-}
dirname__ : Task JavaScript.Error String
dirname__ =
    JavaScript.run "__dirname"
        |> JavaScript.decode Decode.string


{-| To get real path.
-}
realPath : String -> Task JavaScript.Error String
realPath _ =
    JavaScript.run "await require('fs/promises').realpath(_v0, 'utf8')"
        |> JavaScript.decode Decode.string



--


{-| To create directory recursively.
-}
mkDir : String -> Task JavaScript.Error ()
mkDir _ =
    JavaScript.run "await require('fs/promises').mkdir(_v0, { recursive: true })"
        |> JavaScript.decode (Decode.succeed ())


{-| To read file.
-}
readFile : String -> Task JavaScript.Error String
readFile _ =
    JavaScript.run "await require('fs/promises').readFile(_v0, 'utf8')"
        |> JavaScript.decode Decode.string


{-| To write file.
-}
writeFile : String -> String -> Task JavaScript.Error ()
writeFile _ _ =
    JavaScript.run "await require('fs/promises').writeFile(_v0, _v1)"
        |> JavaScript.decode (Decode.succeed ())


{-| To copy file.
-}
copyFile : String -> String -> Task JavaScript.Error ()
copyFile _ _ =
    JavaScript.run "await require('fs/promises').copyFile(_v0, _v1)"
        |> JavaScript.decode (Decode.succeed ())
