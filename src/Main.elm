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


type Error
    = BadArguments
    | Exception JavaScript.Exception


mainCmd : Cmd ()
mainCmd =
    mainTask
        |> Task.andThen
            (\v ->
                NodeJs.consoleLog v
                    |> Task.mapError Exception
            )
        |> Task.onError
            (\v ->
                (case v of
                    BadArguments ->
                        "Usage: elm-json-interop <File.elm>..."

                    Exception vv ->
                        "elm-json-interop failed: " ++ JavaScript.exceptionToString vv
                )
                    |> NodeJs.consoleError
                    |> Task.andThen (\_ -> NodeJs.processExit 1)
            )
        |> Task.attempt (\_ -> ())


mainTask : Task Error String
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
                    Task.fail BadArguments

                a ->
                    a
                        |> List.map processFile
                        |> Task.sequence
                        |> Task.map
                            (\v ->
                                "JSON encoders/decoders have been generated for " ++ fileCount v ++ "."
                            )
                        |> Task.mapError Exception
        )
        (NodeJs.getArguments
            |> Task.mapError Exception
        )


processFile : String -> Task Exception String
processFile path =
    Task.map2
        (\a b ->
            Task.andThen
                (\c ->
                    processFile_ a b c
                )
                (readAndParseElmFile b)
        )
        NodeJs.dirname__
        (NodeJs.realPath path)
        |> Task.andThen identity


processFile_ : String -> String -> RawFile -> Task Exception String
processFile_ binPath fullPath rawFile =
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


readAndParseElmFile : String -> Task Exception RawFile
readAndParseElmFile a =
    a
        |> NodeJs.readFile
        |> Task.andThen
            (\v ->
                v
                    |> Elm.Parser.parse
                    |> Result.mapError
                        (\vv ->
                            JavaScript.Exception ("I can't parse \"" ++ a ++ "\", because: " ++ deadEndsToString vv ++ ".")
                        )
                    |> Task_.fromResult
            )



--


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
