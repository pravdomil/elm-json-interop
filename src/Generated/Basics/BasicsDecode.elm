module Generated.Basics.BasicsDecode exposing (..)

import Dict exposing (Dict)
import Json.Decode exposing (..)
import Set exposing (Set)


charDecoder : Decoder Char
charDecoder =
    string
        |> andThen
            (\a ->
                case a |> String.toList of
                    b :: [] ->
                        succeed b

                    _ ->
                        fail "I was expecting exactly one char."
            )


setDecoder : Decoder comparable -> Decoder (Set comparable)
setDecoder a =
    map Set.fromList (list a)


dictDecoder : Decoder k -> Decoder v -> Decoder (Dict String v)
dictDecoder _ a =
    dict a


nullableOrMissingField : String -> Decoder (Maybe a) -> Decoder (Maybe a)
nullableOrMissingField name a =
    oneOf
        [ map Just (field name value)
        , succeed Nothing
        ]
        |> andThen
            (\v ->
                case v of
                    Just _ ->
                        field name a

                    Nothing ->
                        succeed Nothing
            )


resultDecoder : Decoder e -> Decoder v -> Decoder (Result e v)
resultDecoder t_error t_value =
    index 0 string
        |> andThen
            (\tag ->
                case tag of
                    "Ok" ->
                        map Ok t_value

                    "Err" ->
                        map Err t_error

                    _ ->
                        fail ("I can't decode Result, what " ++ tag ++ " means?")
            )



--


