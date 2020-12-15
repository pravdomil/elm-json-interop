module Main exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.RawFile exposing (RawFile)
import Elm.Syntax.File exposing (File)
import Generators.Decode as Decode
import Generators.Encode as Encode
import Interop.JsCode exposing (..)
import Parser exposing (deadEndsToString)
import Regex
import Task exposing (Task)
import Utils.Task_ exposing (..)
import Utils.Utils exposing (regexReplace)


{-| To define main entry point.
-}
main : Program () () ()
main =
    cliProgram
        (run
            |> Task.andThen consoleLog
            |> Task.onError (\v -> consoleError v |> Task.andThen (\_ -> processExit 1))
            |> Task.attempt (\_ -> ())
        )


{-| To show usage or process input files.
-}
run : Task Error String
run =
    let
        fileCount : List a -> String
        fileCount b =
            let
                len : Int
                len =
                    b |> List.length
            in
            String.fromInt len
                ++ (if len == 1 then
                        " module"

                    else
                        " modules"
                   )
    in
    Task.andThen
        (\args ->
            case args |> List.drop 2 of
                [] ->
                    Task.fail usage

                a ->
                    a
                        |> List.map processFile
                        |> Task.sequence
                        |> Task.map
                            (\v ->
                                "I have generated JSON encoders/decoders for " ++ fileCount v ++ "."
                            )
        )
        getArguments


{-| To get program usage.
-}
usage : String
usage =
    "Usage: elm-json-interop <File.elm>..."


{-| To process file.
-}
processFile : String -> Task Error String
processFile path =
    let
        generateTask : String -> String -> String -> RawFile -> Task Error String
        generateTask binPath fullPath srcFolder rawFile =
            let
                folderPath : String
                folderPath =
                    fullPath |> dirname

                file : File
                file =
                    rawFile |> Processing.process Processing.init
            in
            [ mkDir (srcFolder ++ "Utils/Basics")
            , copyFile (binPath ++ "/../src/Utils/Basics/Encode.elm") (srcFolder ++ "Utils/Basics/Encode.elm")
            , copyFile (binPath ++ "/../src/Utils/Basics/Decode.elm") (srcFolder ++ "Utils/Basics/Decode.elm")
            , writeFile (folderPath ++ "/Encode.elm") (Encode.fromFile file)
            , writeFile (folderPath ++ "/Decode.elm") (Decode.fromFile file)
            ]
                |> Task.sequence
                |> Task.map (\_ -> fullPath)
    in
    taskAndThen2
        (\a b ->
            taskAndThen2
                (\c d ->
                    generateTask a b c d
                )
                (srcFolderPathTask b)
                (readAndParseElmFile b)
        )
        dirname__
        (realPath path)


{-| -}
srcFolderPath : String -> Maybe String
srcFolderPath path =
    path
        |> Regex.find ("^.*/src/" |> Regex.fromString |> Maybe.withDefault Regex.never)
        |> List.head
        |> Maybe.map .match


{-| -}
srcFolderPathTask : String -> Task Error String
srcFolderPathTask a =
    a |> srcFolderPath |> fromMaybe "Elm file must be inside \"src\" folder."


{-| -}
readAndParseElmFile : String -> Task Error RawFile
readAndParseElmFile a =
    a
        |> readFile
        |> Task.andThen
            (\v ->
                v
                    |> Elm.Parser.parse
                    |> Result.mapError (\vv -> "I can't parse \"" ++ a ++ "\", because: " ++ deadEndsToString vv ++ ".")
                    |> fromResult
            )



--


{-| To get basename.
-}
basename : String -> String -> String
basename extension a =
    a
        |> regexReplace "^.*/" (always "")
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
    a |> regexReplace "/[^/]+$" (always "")
