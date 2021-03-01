module Main exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.RawFile exposing (RawFile)
import Elm.Syntax.File exposing (File)
import Generators.Decode as Decode
import Generators.Encode as Encode
import Interop.JavaScript as JavaScript exposing (Exception)
import Interop.NodeJs as NodeJs
import Parser exposing (deadEndsToString)
import Regex
import Task exposing (Task)
import Utils.Task_ as Task_


main : Program () () ()
main =
    Platform.worker
        { init = \_ -> ( (), mainCmd )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


mainCmd : Cmd ()
mainCmd =
    mainTask
        |> Task.andThen
            (\v ->
                case v of
                    Ok vv ->
                        NodeJs.consoleLog vv

                    Err vv ->
                        NodeJs.consoleLog vv
                            |> Task.andThen (\_ -> NodeJs.processExit 1)
            )
        |> Task.onError
            (\v ->
                NodeJs.consoleError ("elm-json-interop failed: " ++ JavaScript.exceptionToString v)
                    |> Task.andThen (\_ -> NodeJs.processExit 1)
            )
        |> Task.attempt (\_ -> ())


mainTask : Task Exception (Result String String)
mainTask =
    let
        fileCount : List a -> String
        fileCount b =
            let
                len : Int
                len =
                    List.length b

                suffix : String
                suffix =
                    if len == 1 then
                        " module"

                    else
                        " modules"
            in
            String.fromInt len ++ suffix
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


usage : String
usage =
    "Usage: elm-json-interop <File.elm>..."


processFile : String -> Task String String
processFile path =
    let
        generateTask : String -> String -> RawFile -> Task String String
        generateTask binPath fullPath rawFile =
            let
                ( dirname, basename ) =
                    fullPath |> split

                file : File
                file =
                    rawFile |> Processing.process Processing.init
            in
            (case fullPath |> srcFolderPath of
                Just srcFolder ->
                    [ NodeJs.mkDir (srcFolder ++ "Utils/Json")
                    , NodeJs.copyFile (binPath ++ "/../src/Utils/Json/Encode_.elm") (srcFolder ++ "Utils/Json/Encode_.elm")
                    , NodeJs.copyFile (binPath ++ "/../src/Utils/Json/Decode_.elm") (srcFolder ++ "Utils/Json/Decode_.elm")
                    ]

                Nothing ->
                    []
            )
                ++ [ NodeJs.mkDir (dirname ++ "/" ++ basename)
                   , NodeJs.writeFile (dirname ++ "/" ++ basename ++ "/Encode.elm") (Encode.fromFile file)
                   , NodeJs.writeFile (dirname ++ "/" ++ basename ++ "/Decode.elm") (Decode.fromFile file)
                   ]
                |> Task.sequence
                |> Task.map (\_ -> fullPath)
    in
    Task.map2
        (\a b ->
            Task.map
                (\c ->
                    generateTask a b c
                )
                (readAndParseElmFile b)
                |> Task.andThen identity
        )
        NodeJs.dirname__
        (NodeJs.realPath path)
        |> Task.andThen identity


srcFolderPath : String -> Maybe String
srcFolderPath path =
    let
        regex : Regex.Regex
        regex =
            Regex.fromString "^.*/src/" |> Maybe.withDefault Regex.never
    in
    path
        |> Regex.find regex
        |> List.head
        |> Maybe.map .match


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
