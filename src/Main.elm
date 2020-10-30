module Main exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.Syntax.File exposing (File)
import Eval exposing (consoleErrorAndExit, consoleLog, getArguments, mkDir, readFile, realPath, writeFile)
import Generators.Decode exposing (fileToElmDecoderModule)
import Generators.Encode exposing (toElmEncoder)
import Generators.TypeScript exposing (toTypeScript)
import Parser exposing (deadEndsToString)
import Regex
import String exposing (contains, join, replace)


{-| To define main entry point.
-}
main : Program () () ()
main =
    Platform.worker
        { init = \_ -> ( run (), Cmd.none )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


{-| To show usage or process input files.
-}
run : () -> ()
run _ =
    let
        elmFiles : List String
        elmFiles =
            getArguments () |> List.drop 2
    in
    if elmFiles |> List.isEmpty then
        usage |> consoleErrorAndExit

    else
        elmFiles |> List.map processElmFile |> join "\n" |> consoleLog


{-| To get program usage.
-}
usage : String
usage =
    "Usage: elm-json-interop [File.elm ...]"


{-| To process Elm file.
-}
processElmFile : String -> String
processElmFile a =
    let
        path : String
        path =
            a |> realPath

        _ =
            if path |> contains "/src/" then
                ()

            else
                "Elm file must be inside \"src\" folder." |> consoleErrorAndExit
    in
    case path |> readFile |> Elm.Parser.parse of
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
                    [ folderPath |> mkDir |> (\_ -> ())
                    , file |> toElmEncoder |> writeFile (folderPath ++ "/" ++ fileName ++ "Encode.elm")
                    , file |> fileToElmDecoderModule |> writeFile (folderPath ++ "/" ++ fileName ++ "Decode.elm")
                    , file |> toTypeScript |> writeFile (folderPath ++ "/" ++ fileName ++ ".ts")
                    ]
            in
            "I have generated Elm encoder, Elm decoder, TypeScript definitions in folder:\n" ++ folderPath

        Err b ->
            ("I can't parse \"" ++ a ++ "\", because: " ++ deadEndsToString b ++ ".")
                |> consoleErrorAndExit
                |> (\_ -> "")


{-| To get basename.
-}
basename : String -> String -> String
basename extension path =
    path
        |> (\v ->
                v
                    |> Regex.replace
                        ("^.*/" |> Regex.fromString |> Maybe.withDefault Regex.never)
                        (\_ -> "")
           )
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
    a
        |> Regex.replace
            ("/[^/]+$" |> Regex.fromString |> Maybe.withDefault Regex.never)
            (\_ -> "")
