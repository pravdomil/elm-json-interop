port module Main exposing (..)

import Program exposing (parse)


type alias Input =
    { argv : List String, stdin : String }


type alias Output =
    { code : Int, stdout : String, stderr : String }


main : Program Input () ()
main =
    Platform.worker
        { init = \flags -> ( (), exit (run flags) )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


run : Input -> Output
run { stdin, argv } =
    let
        result =
            parse stdin
    in
    case result of
        Ok value ->
            Output 0 value ""

        Err error ->
            Output 1 "" ("I stopped because,\n" ++ error ++ "\n")


port exit : Output -> Cmd msg
