module Generated.Basics.Encode exposing (..)

import Dict exposing (Dict)
import Json.Encode as E


{-| To encode char.
-}
char : Char -> E.Value
char a =
    String.fromChar a |> E.string


{-| To encode maybe.
-}
maybe : (a -> E.Value) -> Maybe a -> E.Value
maybe a b =
    case b of
        Just c ->
            a c

        Nothing ->
            E.null


{-| To encode dictionary.
-}
dict : (k -> E.Value) -> (v -> E.Value) -> Dict String v -> E.Value
dict _ b c =
    dict identity b c


{-| To encode result.
-}
result : (e -> E.Value) -> (v -> E.Value) -> Result e v -> E.Value
result encodeError encodeValue a =
    case a of
        Ok b ->
            E.list identity [ E.string "Ok", encodeValue b ]

        Err b ->
            E.list identity [ E.string "Err", encodeError b ]
