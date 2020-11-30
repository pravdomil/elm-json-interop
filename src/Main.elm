module Main exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.RawFile exposing (RawFile)
import Elm.Syntax.File exposing (File)
import Generators.Decoder as Decoder
import Generators.Encoder as Encoder
import Interop.JsCode exposing (..)
import Parser exposing (deadEndsToString)
import Regex
import String exposing (join, replace)
import Task exposing (Task)
import Utils.TaskUtils exposing (..)
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
    Task.andThen
        (\args ->
            case args |> List.drop 2 of
                [] ->
                    Task.fail usage

                a ->
                    a
                        |> List.map processFile
                        |> Task.sequence
                        |> Task.map (join "\n")
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
                generatedFolder : String
                generatedFolder =
                    (fullPath |> replace srcFolder (srcFolder ++ "Generated/") |> dirname) ++ "/" ++ moduleName

                moduleName : String
                moduleName =
                    fullPath |> basename ".elm"

                file : File
                file =
                    rawFile |> Processing.process Processing.init
            in
            [ mkDir (srcFolder ++ "Generated/Basics")
            , copyFile (binPath ++ "/../src/Generated/Basics/Encode.elm") (srcFolder ++ "Generated/Basics/Encode.elm")
            , copyFile (binPath ++ "/../src/Generated/Basics/Decode.elm") (srcFolder ++ "Generated/Basics/Decode.elm")
            , mkDir generatedFolder
            , writeFile (generatedFolder ++ "/Encode.elm") (Encoder.fromFile file)
            , writeFile (generatedFolder ++ "/Decode.elm") (Decoder.fromFile file)
            ]
                |> Task.sequence
                |> Task.map
                    (\_ ->
                        "I have generated JSON encoders/decoders in folder:\n" ++ generatedFolder
                    )
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
    a |> srcFolderPath |> maybeToTask "Elm file must be inside \"src\" folder."


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
                    |> resultToTask
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
