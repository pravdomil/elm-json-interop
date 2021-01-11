module Interop.JsCode exposing (..)

{-| Read <https://guide.elm-lang.org/interop/limits.html>.
-}

import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)
import Utils.Task_ as Task_


{-| To define error.
-}
type alias Error =
    String


{-| To create command line program.
-}
cliProgram : Cmd msg -> Program flags () msg
cliProgram init =
    Platform.worker
        { init = \_ -> ( (), init )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }



--


{-| To run JavaScript code. Function implementation gets replaced by actual function in build step.
-}
eval : String -> Task String Decode.Value
eval _ =
    Task.fail "Function is not implemented."



--


{-| To get program arguments.
<https://stackoverflow.com/questions/9725675/is-there-a-standard-format-for-command-line-shell-help-text>
-}
getArguments : Task Error (List String)
getArguments =
    eval "process.argv"
        |> Task_.andThenDecode (Decode.list Decode.string)


{-| To get stdin.
-}
getStdin : Task Error (Maybe String)
getStdin =
    eval "process.stdin.isTTY ? null : require('fs/promises').readFile(0, 'utf8')"
        |> Task_.andThenDecode (Decode.nullable Decode.string)



--


{-| To call console.log function.
-}
consoleLog : String -> Task Error ()
consoleLog _ =
    eval "console.log(_v0)"
        |> Task_.andThenDecode (Decode.succeed ())


{-| To call console.error function.
-}
consoleError : String -> Task Error ()
consoleError _ =
    eval "console.error(_v0)"
        |> Task_.andThenDecode (Decode.succeed ())


{-| To kill process with exit code.
-}
processExit : Int -> Task Error ()
processExit _ =
    eval "process.exit(_v0)"
        |> Task_.andThenDecode (Decode.succeed ())



--


{-| To get \_\_filename.
-}
filename__ : Task Error String
filename__ =
    eval "__filename"
        |> Task_.andThenDecode Decode.string


{-| To get \_\_dirname.
-}
dirname__ : Task Error String
dirname__ =
    eval "__dirname"
        |> Task_.andThenDecode Decode.string


{-| To get real path.
-}
realPath : String -> Task Error String
realPath _ =
    eval "require('fs/promises').realpath(_v0, 'utf8')"
        |> Task_.andThenDecode Decode.string



--


{-| To create directory recursively.
-}
mkDir : String -> Task Error ()
mkDir _ =
    eval "require('fs/promises').mkdir(_v0, { recursive: true })"
        |> Task_.andThenDecode (Decode.succeed ())


{-| To read file.
-}
readFile : String -> Task Error String
readFile _ =
    eval "require('fs/promises').readFile(_v0, 'utf8')"
        |> Task_.andThenDecode Decode.string


{-| To write file.
-}
writeFile : String -> String -> Task Error ()
writeFile _ _ =
    eval "require('fs/promises').writeFile(_v0, _v1)"
        |> Task_.andThenDecode (Decode.succeed ())


{-| To copy file.
-}
copyFile : String -> String -> Task Error ()
copyFile _ _ =
    eval "require('fs/promises').copyFile(_v0, _v1)"
        |> Task_.andThenDecode (Decode.succeed ())
