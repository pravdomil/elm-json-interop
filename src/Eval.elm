module Eval exposing (..)

import Json.Decode as Decode exposing (Decoder, decodeValue)
import Json.Encode as Encode exposing (Value, encode)
import Task exposing (Task)


{-| To define JavaScript error.
-}
type alias Error =
    { name : String
    , message : String
    , stack : Maybe String
    }



--


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


{-| To run JavaScript code. Function implementation gets replaced by eval() function.
-}
eval : Decoder a -> String -> Task Error a
eval _ _ =
    Task.fail (Error "NotImplemented" "Function is not implemented." Nothing)



--


{-| To get program arguments.
-}
getArguments : Task Error (List String)
getArguments =
    "process.argv"
        |> eval (Decode.list Decode.string)


{-| To get stdin.
-}
getStdin : Task Error (Maybe String)
getStdin =
    "process.stdin.isTTY ? null : require('fs').readFileSync(0, 'utf8')"
        |> eval (Decode.maybe Decode.string)



--


{-| To call console.log function.
-}
consoleLog : String -> Task Error ()
consoleLog message =
    ("console.log(" ++ toString message ++ ")")
        |> eval (Decode.succeed ())


{-| To call console.error and kill process with 1 exit code.
-}
consoleErrorAndExit : String -> Task Error ()
consoleErrorAndExit message =
    ("console.error(" ++ toString message ++ ");process.exit(1);")
        |> eval (Decode.succeed ())



--


{-| To get \_\_filename.
-}
filename__ : Task Error String
filename__ =
    "__filename"
        |> eval Decode.string


{-| To get \_\_dirname.
-}
dirname__ : Task Error String
dirname__ =
    "__dirname"
        |> eval Decode.string


{-| To get real path.
-}
realPath : String -> Task Error String
realPath path =
    ("require('fs').realpathSync(" ++ toString path ++ ", 'utf8')")
        |> eval Decode.string



--


{-| To create directory recursively.
-}
mkDir : String -> Task Error ()
mkDir path =
    ("require('fs').mkdirSync(" ++ toString path ++ ", { recursive: true })")
        |> eval (Decode.succeed ())


{-| To read file.
-}
readFile : String -> Task Error String
readFile path =
    ("require('fs').readFileSync(" ++ toString path ++ ", 'utf8')")
        |> eval Decode.string


{-| To write file.
-}
writeFile : String -> String -> Task Error ()
writeFile path content =
    ("require('fs').writeFileSync(" ++ toString path ++ ", " ++ toString content ++ ")")
        |> eval (Decode.succeed ())


{-| To copy file.
-}
copyFile : String -> String -> Task Error ()
copyFile source destination =
    ("require('fs').copyFileSync(" ++ toString source ++ ", " ++ toString destination ++ ")")
        |> eval (Decode.succeed ())



--


{-| To encode string into JSON string.
-}
toString : String -> String
toString a =
    a |> Encode.string |> encode 0
