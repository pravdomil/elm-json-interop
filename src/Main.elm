module Main exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.Syntax.File exposing (File)
import Eval exposing (Eval, cliProgram, consoleErrorAndExit, consoleLog, getArguments, mkDir, readFile, realPath, writeFile)
import Generators.Decode exposing (fileToElmDecodeModule)
import Generators.Encode exposing (fileToElmEncodeModule)
import Generators.TypeScript exposing (fileToTypeScriptDeclaration)
import Parser exposing (deadEndsToString)
import Regex
import String exposing (contains, join, replace)


{-| To define main entry point.
-}
main : Program () () ()
main =
    cliProgram run


{-| To show usage or process input files.
-}
run : Eval -> ()
run eval =
    let
        elmFiles : List String
        elmFiles =
            getArguments eval |> List.drop 2
    in
    if elmFiles |> List.isEmpty then
        usage |> consoleErrorAndExit eval

    else
        elmFiles |> List.map (processElmFile eval) |> join "\n" |> consoleLog eval


{-| To get program usage.
-}
usage : String
usage =
    "Usage: elm-json-interop [File.elm ...]"


{-| To process Elm file.
-}
processElmFile : Eval -> String -> String
processElmFile eval a =
    let
        path : String
        path =
            a |> realPath eval

        _ =
            if path |> contains "/src/" then
                ()

            else
                "Elm file must be inside \"src\" folder." |> consoleErrorAndExit eval
    in
    case path |> readFile eval |> Elm.Parser.parse of
        Ok rawFile ->
            let
                fileName : String
                fileName =
                    path |> basename ".elm"

                folderPath : String
                folderPath =
                    path |> replace "/src/" "/src/Generated/" |> dirname

                file : File
                file =
                    rawFile |> Processing.process Processing.init

                _ =
                    [ folderPath |> mkDir eval |> (\_ -> ())
                    , file |> fileToElmEncodeModule |> writeFile eval (folderPath ++ "/" ++ fileName ++ "Encode.elm")
                    , file |> fileToElmDecodeModule |> writeFile eval (folderPath ++ "/" ++ fileName ++ "Decode.elm")
                    , file |> fileToTypeScriptDeclaration |> writeFile eval (folderPath ++ "/" ++ fileName ++ ".ts")
                    ]
            in
            "I have generated Elm encoder, Elm decoder, TypeScript declaration in folder:\n" ++ folderPath

        Err b ->
            ("I can't parse \"" ++ a ++ "\", because: " ++ deadEndsToString b ++ ".")
                |> consoleErrorAndExit eval
                |> (\_ -> "")



--


{-| To get basename.
-}
basename : String -> String -> String
basename extension a =
    a
        |> regexReplace "^.*/" ""
        |> (\v ->
                if v |> String.endsWith extension then
                    v |> String.dropRight (extension |> String.length)

                else
                    v
           )


{-| To get dirname.
-}
dirname : String -> String
dirname a =
    a |> regexReplace "/[^/]+$" ""


{-| To do simple regular expression replace.
-}
regexReplace : String -> String -> String -> String
regexReplace regex replacement a =
    a
        |> Regex.replace
            (regex |> Regex.fromString |> Maybe.withDefault Regex.never)
            (\_ -> replacement)
