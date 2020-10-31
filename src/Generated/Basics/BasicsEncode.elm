module Generated.Basics.BasicsEncode exposing (..)

import Dict exposing (Dict)
import Json.Encode exposing (..)


{-| To encode char.
-}
encodeChar : Char -> Value
encodeChar a =
    String.fromChar a |> string


{-| To encode maybe.
-}
encodeMaybe : (a -> Value) -> Maybe a -> Value
encodeMaybe a b =
    case b of
        Just c ->
            a c

        Nothing ->
            null


{-| To encode string.
-}
encodeDict : (k -> Value) -> (v -> Value) -> Dict String v -> Value
encodeDict _ b c =
    dict identity b c


{-| To encode result.
-}
encodeResult : (e -> Value) -> (v -> Value) -> Result e v -> Value
encodeResult t_error t_value a =
    case a of
        Ok b ->
            list identity [ string "Ok", t_value b ]

        Err b ->
            list identity [ string "Err", t_error b ]
