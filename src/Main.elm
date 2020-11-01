module Main exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.RawFile exposing (RawFile)
import Elm.Syntax.File exposing (File)
import Eval exposing (Eval, cliProgram, consoleErrorAndExit, consoleLog, getArguments, mkDir, readFile, realPath, writeFile)
import Generators.Decode exposing (fileToElmDecodeModule)
import Generators.Encode exposing (fileToElmEncodeModule)
import Generators.TypeScript exposing (fileToTypeScriptDeclaration)
import Parser exposing (deadEndsToString)
import Regex
import String exposing (join, replace)


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
    case elmFiles of
        [] ->
            usage |> consoleErrorAndExit eval

        _ ->
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

        srcPath : Result String String
        srcPath =
            path
                |> Regex.find ("^.*/src/" |> Regex.fromString |> Maybe.withDefault Regex.never)
                |> List.head
                |> Maybe.map .match
                |> Result.fromMaybe "Elm file must be inside \"src\" folder."

        rawFile : Result String RawFile
        rawFile =
            path
                |> readFile eval
                |> Elm.Parser.parse
                |> Result.mapError (\v -> "I can't parse \"" ++ a ++ "\", because: " ++ deadEndsToString v ++ ".")
    in
    case Result.map2 Tuple.pair srcPath rawFile of
        Ok ( srcPath_, rawFile_ ) ->
            let
                fileName : String
                fileName =
                    path |> basename ".elm"

                folderPath : String
                folderPath =
                    path |> replace srcPath_ (srcPath_ ++ "Generated/") |> dirname

                file : File
                file =
                    rawFile_ |> Processing.process Processing.init

                _ =
                    [ mkDir eval folderPath
                    , writeFile eval (folderPath ++ "/" ++ fileName ++ "Encode.elm") (fileToElmEncodeModule file)
                    , writeFile eval (folderPath ++ "/" ++ fileName ++ "Decode.elm") (fileToElmDecodeModule file)
                    , writeFile eval (folderPath ++ "/" ++ fileName ++ ".ts") (fileToTypeScriptDeclaration file)
                    ]
            in
            "I have generated Elm encoder, Elm decoder, TypeScript declaration in folder: " ++ folderPath

        Err b ->
            b |> consoleErrorAndExit eval |> (\_ -> "")



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
