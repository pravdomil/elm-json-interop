module Interop.JsCode exposing (..)

{-| Read <https://guide.elm-lang.org/interop/limits.html>.
-}

import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)
import Utils.Task_ exposing (andThenDecode)


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
jsCode : String -> Task String Decode.Value
jsCode _ =
    Task.fail "Function is not implemented."



--


{-| To get program arguments.
<https://stackoverflow.com/questions/9725675/is-there-a-standard-format-for-command-line-shell-help-text>
-}
getArguments : Task Error (List String)
getArguments =
    jsCode "process.argv"
        |> andThenDecode (Decode.list Decode.string)


{-| To get stdin.
-}
getStdin : Task Error (Maybe String)
getStdin =
    jsCode "process.stdin.isTTY ? null : require('fs/promises').readFile(0, 'utf8')"
        |> andThenDecode (Decode.nullable Decode.string)



--


{-| To call console.log function.
-}
consoleLog : String -> Task Error ()
consoleLog _ =
    jsCode "console.log(_v0)"
        |> andThenDecode (Decode.succeed ())


{-| To call console.error function.
-}
consoleError : String -> Task Error ()
consoleError _ =
    jsCode "console.error(_v0)"
        |> andThenDecode (Decode.succeed ())


{-| To kill process with exit code.
-}
processExit : Int -> Task Error ()
processExit _ =
    jsCode "process.exit(_v0)"
        |> andThenDecode (Decode.succeed ())



--


{-| To get \_\_filename.
-}
filename__ : Task Error String
filename__ =
    jsCode "__filename"
        |> andThenDecode Decode.string


{-| To get \_\_dirname.
-}
dirname__ : Task Error String
dirname__ =
    jsCode "__dirname"
        |> andThenDecode Decode.string


{-| To get real path.
-}
realPath : String -> Task Error String
realPath _ =
    jsCode "require('fs/promises').realpath(_v0, 'utf8')"
        |> andThenDecode Decode.string



--


{-| To create directory recursively.
-}
mkDir : String -> Task Error ()
mkDir _ =
    jsCode "require('fs/promises').mkdir(_v0, { recursive: true })"
        |> andThenDecode (Decode.succeed ())


{-| To read file.
-}
readFile : String -> Task Error String
readFile _ =
    jsCode "require('fs/promises').readFile(_v0, 'utf8')"
        |> andThenDecode Decode.string


{-| To write file.
-}
writeFile : String -> String -> Task Error ()
writeFile _ _ =
    jsCode "require('fs/promises').writeFile(_v0, _v1)"
        |> andThenDecode (Decode.succeed ())


{-| To copy file.
-}
copyFile : String -> String -> Task Error ()
copyFile _ _ =
    jsCode "require('fs/promises').copyFile(_v0, _v1)"
        |> andThenDecode (Decode.succeed ())
