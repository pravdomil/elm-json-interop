port module Main exposing (..)

import Json.Decode as Decode exposing (decodeValue, errorToString)
import Json.Encode exposing (Value, list, object, string)
import Program exposing (parse)


main : Program Decode.Value () ()
main =
    Platform.worker
        { init = \flags -> ( (), done (run flags) )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


port done : Value -> Cmd msg


run : Decode.Value -> Value
run value =
    encodeResult <|
        case decodeValue Decode.string value of
            Ok a ->
                parse a

            Err a ->
                Err <| errorToString a


encodeResult : Result String Value -> Value
encodeResult a =
    case a of
        Ok b ->
            object [ ( "Ok", list identity [ b ] ) ]

        Err b ->
            object [ ( "Err", list identity [ string b ] ) ]
