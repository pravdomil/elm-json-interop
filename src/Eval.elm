module Eval exposing (..)

import Json.Decode as Decode exposing (decodeValue)
import Json.Encode as Encode exposing (Value, encode)


{-| -}
type alias Eval =
    String -> Decode.Value


{-| To create command line program.
-}
cliProgram : (Eval -> model) -> Program flags model msg
cliProgram init =
    let
        {- To run JavaScript code. Function implementation gets replaced by eval() function. -}
        eval : Eval
        eval _ =
            Encode.string "EVAL()"
    in
    Platform.worker
        { init = \_ -> ( init eval, Cmd.none )
        , update = \_ m -> ( m, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


{-| To get program arguments.
-}
getArguments : Eval -> List String
getArguments eval =
    "process.argv"
        |> eval
        |> decodeValue (Decode.list Decode.string)
        |> Result.withDefault []


{-| To get stdin.
-}
getStdin : Eval -> Maybe String
getStdin eval =
    "process.stdin.isTTY ? null : require('fs').readFileSync(0, 'utf8')"
        |> eval
        |> decodeValue (Decode.maybe Decode.string)
        |> Result.withDefault Nothing


{-| To call console.log function.
-}
consoleLog : Eval -> String -> ()
consoleLog eval message =
    ("console.log(" ++ toString message ++ ")")
        |> eval
        |> (\_ -> ())


{-| To call console.error and kill process with 1 exit code.
-}
consoleErrorAndExit : Eval -> String -> ()
consoleErrorAndExit eval message =
    ("console.error(" ++ toString message ++ ");process.exit(1);")
        |> eval
        |> (\_ -> ())


{-| To read file.
-}
readFile : Eval -> String -> String
readFile eval path =
    ("require('fs').readFileSync(" ++ toString path ++ ", 'utf8')")
        |> eval
        |> decodeValue Decode.string
        |> Result.withDefault ""


{-| To write file.
-}
writeFile : Eval -> String -> String -> ()
writeFile eval path content =
    ("require('fs').writeFileSync(" ++ toString path ++ ", " ++ toString content ++ ")")
        |> eval
        |> (\_ -> ())


{-| To create directory recursively.
-}
mkDir : Eval -> String -> ()
mkDir eval path =
    ("require('fs').mkdirSync(" ++ toString path ++ ", { recursive: true })")
        |> eval
        |> (\_ -> ())


{-| To get real path.
-}
realPath : Eval -> String -> String
realPath eval path =
    ("require('fs').realpathSync(" ++ toString path ++ ", 'utf8')")
        |> eval
        |> decodeValue Decode.string
        |> Result.withDefault ""


{-| To encode string into JSON string.
-}
toString : String -> String
toString a =
    a |> Encode.string |> encode 0
