module Interop.JavaScript exposing (..)

{-| Part of <https://github.com/pravdomil/Elm-FFI>.
-}

import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


run : String -> Task Error Decode.Value
run _ =
    let
        _ =
            anyDecoder

        _ =
            Exception
    in
    Task.fail FileNotPatched


decode : Decoder a -> Task Error Decode.Value -> Task Error a
decode decoder a =
    a
        |> Task.andThen
            (\v ->
                case v |> Decode.decodeValue decoder of
                    Ok b ->
                        Task.succeed b

                    Err b ->
                        Task.fail (DecodeError b)
            )


anyDecoder : Decoder a
anyDecoder =
    Decode.fail (errorToString FileNotPatched)



--


type Error
    = FileNotPatched
    | Exception Decode.Value
    | DecodeError Decode.Error


errorToString : Error -> String
errorToString a =
    case a of
        FileNotPatched ->
            "Compiled file needs to be processed via elm-ffi command."

        Exception b ->
            "Got JavaScript exception:\n"
                ++ (b
                        |> Decode.decodeValue (Decode.field "message" Decode.string)
                        |> Result.withDefault "No message provided."
                   )

        DecodeError b ->
            "Cannot decode JavaScript value because:\n" ++ Decode.errorToString b
