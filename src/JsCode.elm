module JsCode exposing (..)

{-| Read <https://guide.elm-lang.org/interop/limits.html>.
-}

import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)
import TaskUtil exposing (decodeTask)


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
-}
getArguments : Task Error (List String)
getArguments =
    jsCode "process.argv"
        |> decodeTask (Decode.list Decode.string)


{-| To get stdin.
-}
getStdin : Task Error (Maybe String)
getStdin =
    jsCode "process.stdin.isTTY ? null : require('fs').readFileSync(0, 'utf8')"
        |> decodeTask (Decode.maybe Decode.string)



--


{-| To call console.log function.
-}
consoleLog : String -> Task Error ()
consoleLog _ =
    jsCode "console.log(_v0)"
        |> decodeTask (Decode.succeed ())


{-| To call console.error function.
-}
consoleError : String -> Task Error ()
consoleError _ =
    jsCode "console.error(_v0)"
        |> decodeTask (Decode.succeed ())


{-| To kill process with exit code.
-}
processExit : Int -> Task Error ()
processExit _ =
    jsCode "process.exit(_v0)"
        |> decodeTask (Decode.succeed ())



--


{-| To get \_\_filename.
-}
filename__ : Task Error String
filename__ =
    jsCode "__filename"
        |> decodeTask Decode.string


{-| To get \_\_dirname.
-}
dirname__ : Task Error String
dirname__ =
    jsCode "__dirname"
        |> decodeTask Decode.string


{-| To get real path.
-}
realPath : String -> Task Error String
realPath _ =
    jsCode "require('fs').realpathSync(_v0, 'utf8')"
        |> decodeTask Decode.string



--


{-| To create directory recursively.
-}
mkDir : String -> Task Error ()
mkDir _ =
    jsCode "require('fs').mkdirSync(_v0, { recursive: true })"
        |> decodeTask (Decode.succeed ())


{-| To read file.
-}
readFile : String -> Task Error String
readFile _ =
    jsCode "require('fs').readFileSync(_v0, 'utf8')"
        |> decodeTask Decode.string


{-| To write file.
-}
writeFile : String -> String -> Task Error ()
writeFile _ _ =
    jsCode "require('fs').writeFileSync(_v0, _v1)"
        |> decodeTask (Decode.succeed ())


{-| To copy file.
-}
copyFile : String -> String -> Task Error ()
copyFile _ _ =
    jsCode "require('fs').copyFileSync(_v0, _v1)"
        |> decodeTask (Decode.succeed ())
