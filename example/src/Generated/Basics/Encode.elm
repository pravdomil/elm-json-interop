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
maybe encode a =
    case a of
        Just b ->
            encode b

        Nothing ->
            E.null


{-| To encode dictionary.
-}
dict : (comparable -> E.Value) -> (v -> E.Value) -> Dict comparable v -> E.Value
dict encodeKey encodeValue a =
    a
        |> Dict.toList
        |> E.list (\( k, v ) -> E.list identity [ encodeKey k, encodeValue v ])


{-| To encode result.
-}
result : (e -> E.Value) -> (v -> E.Value) -> Result e v -> E.Value
result encodeError encodeValue a =
    case a of
        Ok b ->
            E.object [ ( "type", E.string "Ok" ), ( "a", encodeValue b ) ]

        Err b ->
            E.object [ ( "type", E.string "Err" ), ( "a", encodeError b ) ]
