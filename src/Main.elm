module Main exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.RawFile exposing (RawFile)
import Elm.Syntax.File exposing (File)
import Generators.Decode as Decode
import Generators.Encode as Encode
import Interop.NodeJs as NodeJs
import Parser exposing (deadEndsToString)
import Regex
import Task exposing (Task)
import Utils.Task_ as Task_
import Utils.Utils exposing (regexReplace)


{-| To define main entry point.
-}
main : Program () () ()
main =
    Platform.worker
        { init = \_ -> ( (), init )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


init : Cmd ()
init =
    run
        |> Task.andThen NodeJs.consoleLog
        |> Task.onError (\v -> NodeJs.consoleError v |> Task.andThen (\_ -> NodeJs.processExit 1))
        |> Task.attempt (\_ -> ())


{-| To show usage or process input files.
-}
run : Task String String
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
                                "JSON encoders/decoders have been generated for " ++ fileCount v ++ "."
                            )
        )
        NodeJs.getArguments


{-| To get program usage.
-}
usage : String
usage =
    "Usage: elm-json-interop <File.elm>..."


{-| To process file.
-}
processFile : String -> Task String String
processFile path =
    let
        generateTask : String -> String -> String -> RawFile -> Task String String
        generateTask binPath fullPath srcFolder rawFile =
            let
                ( dirname, basename ) =
                    fullPath |> split

                file : File
                file =
                    rawFile |> Processing.process Processing.init
            in
            [ NodeJs.mkDir (srcFolder ++ "Utils/Json")
            , NodeJs.copyFile (binPath ++ "/../src/Utils/Json/Encode_.elm") (srcFolder ++ "Utils/Json/Encode_.elm")
            , NodeJs.copyFile (binPath ++ "/../src/Utils/Json/Decode_.elm") (srcFolder ++ "Utils/Json/Decode_.elm")
            , NodeJs.mkDir (dirname ++ "/" ++ basename)
            , NodeJs.writeFile (dirname ++ "/" ++ basename ++ "/Encode.elm") (Encode.fromFile file)
            , NodeJs.writeFile (dirname ++ "/" ++ basename ++ "/Decode.elm") (Decode.fromFile file)
            ]
                |> Task.sequence
                |> Task.map (\_ -> fullPath)
    in
    Task.map2
        (\a b ->
            Task.map2
                (\c d ->
                    generateTask a b c d
                )
                (srcFolderPathTask b)
                (readAndParseElmFile b)
                |> Task.andThen identity
        )
        NodeJs.dirname__
        (NodeJs.realPath path)
        |> Task.andThen identity


srcFolderPath : String -> Maybe String
srcFolderPath path =
    path
        |> Regex.find ("^.*/src/" |> Regex.fromString |> Maybe.withDefault Regex.never)
        |> List.head
        |> Maybe.map .match


srcFolderPathTask : String -> Task String String
srcFolderPathTask a =
    a |> srcFolderPath |> Task_.fromMaybe "Elm file must be inside \"src\" folder."


readAndParseElmFile : String -> Task String RawFile
readAndParseElmFile a =
    a
        |> NodeJs.readFile
        |> Task.andThen
            (\v ->
                v
                    |> Elm.Parser.parse
                    |> Result.mapError (\vv -> "I can't parse \"" ++ a ++ "\", because: " ++ deadEndsToString vv ++ ".")
                    |> Task_.fromResult
            )



--


{-| To get dirname and basename.
-}
split : String -> ( String, String )
split a =
    case a |> String.split "/" |> List.reverse of
        b :: rest ->
            ( rest |> List.reverse |> String.join "/"
            , b |> String.split "." |> List.reverse |> List.drop 1 |> List.reverse |> String.join "."
            )

        _ ->
            ( a, "" )
