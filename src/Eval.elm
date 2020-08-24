module Eval exposing (..)

import Json.Encode as Encode exposing (Value, encode)


{-| This function gets replaced by real eval() JavaScript function.
-}
eval : String -> String
eval a =
    a


{-| To call console.log function.
-}
consoleLog : String -> String
consoleLog message =
    "console.log(" ++ toString message ++ ")" |> eval


{-| To call console.error and kill process with 1 exit code.
-}
consoleErrorAndExit : String -> String
consoleErrorAndExit message =
    "console.error(" ++ toString message ++ ");process.exit(1);" |> eval


{-| To read file.
-}
readFile : String -> String
readFile path =
    "require('fs').readFileSync(" ++ toString path ++ ", 'utf-8')" |> eval


{-| To write file.
-}
writeFile : String -> String -> String
writeFile path content =
    "require('fs').writeFileSync(" ++ toString path ++ ", " ++ toString content ++ ")" |> eval


{-| To encode string into JSON string.
-}
toString : String -> String
toString a =
    a |> Encode.string |> encode 0
