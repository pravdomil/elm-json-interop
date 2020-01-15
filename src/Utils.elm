module Utils exposing (..)

import Json.Encode


type alias Argument =
    { prefix : String, char : Int, suffix : String, disabled : Bool }


argumentToString : Argument -> String
argumentToString { prefix, char, suffix, disabled } =
    case disabled of
        True ->
            ""

        False ->
            let
                constant =
                    stringFromAlphabet char ++ suffix
            in
            case prefix == "" of
                True ->
                    " " ++ constant

                False ->
                    " (" ++ prefix ++ " " ++ constant ++ ")"


type alias Prefix =
    { prefix : String }


prefixToString : Prefix -> String
prefixToString { prefix } =
    case prefix == "" of
        True ->
            ""

        False ->
            " " ++ prefix


toJsonString : String -> String
toJsonString a =
    Json.Encode.encode 0 (Json.Encode.string a)


stringFromAlphabet : Int -> String
stringFromAlphabet a =
    String.fromChar <| Char.fromCode <| (+) 97 a


tupleDestructor : Int -> Int -> String
tupleDestructor len i =
    case len of
        2 ->
            case i + 1 of
                1 ->
                    "Tuple.first"

                2 ->
                    "Tuple.second"

                _ ->
                    ""

        3 ->
            case i + 1 of
                1 ->
                    "(\\( first, _, _ ) -> first)"

                2 ->
                    "(\\( _, second, _ ) -> second)"

                3 ->
                    "(\\( _, _, third ) -> third)"

                _ ->
                    ""

        _ ->
            ""


tupleConstructor : Int -> String
tupleConstructor len =
    case len of
        2 ->
            "Tuple.pair"

        3 ->
            "(\\a b c -> (a, b, c))"

        _ ->
            ""


mapFn : Int -> String
mapFn a =
    case a of
        1 ->
            "map"

        b ->
            "map" ++ String.fromInt b
