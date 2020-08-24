module Eval exposing (..)

import Json.Decode as Decode exposing (decodeValue)
import Json.Encode as Encode exposing (Value, encode)


{-| To run JavaScript code. Function implementation gets replaced by eval() function.
-}
eval : String -> Decode.Value
eval _ =
    Encode.null


{-| To get program arguments.
-}
getArguments : () -> List String
getArguments _ =
    "process.argv"
        |> eval
        |> decodeValue (Decode.list Decode.string)
        |> Result.withDefault []


{-| To get stdin.
-}
getStdin : () -> Maybe String
getStdin _ =
    "process.stdin.isTTY ? null : require('fs').readFileSync(0, 'utf8');"
        |> eval
        |> decodeValue (Decode.maybe Decode.string)
        |> Result.withDefault Nothing


{-| To call console.log function.
-}
consoleLog : String -> ()
consoleLog message =
    ("console.log(" ++ toString message ++ ")")
        |> eval
        |> Decode.decodeValue (Decode.succeed ())
        |> Result.withDefault ()


{-| To call console.error and kill process with 1 exit code.
-}
consoleErrorAndExit : String -> ()
consoleErrorAndExit message =
    ("console.error(" ++ toString message ++ ");process.exit(1);")
        |> eval
        |> Decode.decodeValue (Decode.succeed ())
        |> Result.withDefault ()


{-| To read file.
-}
readFile : String -> String
readFile path =
    ("require('fs').readFileSync(" ++ toString path ++ ", 'utf8')")
        |> eval
        |> decodeValue Decode.string
        |> Result.withDefault ""


{-| To write file.
-}
writeFile : String -> String -> ()
writeFile path content =
    ("require('fs').writeFileSync(" ++ toString path ++ ", " ++ toString content ++ ")")
        |> eval
        |> Decode.decodeValue (Decode.succeed ())
        |> Result.withDefault ()


{-| To create directory recursively.
-}
mkDir : String -> Maybe String
mkDir path =
    ("require('fs').mkdirSync(" ++ toString path ++ ", { recursive: true })")
        |> eval
        |> decodeValue (Decode.maybe Decode.string)
        |> Result.withDefault Nothing


{-| To get real path.
-}
realPath : String -> String
realPath path =
    ("require('fs').realpathSync(" ++ toString path ++ ", 'utf8')")
        |> eval
        |> decodeValue Decode.string
        |> Result.withDefault ""


{-| To encode string into JSON string.
-}
toString : String -> String
toString a =
    a |> Encode.string |> encode 0
