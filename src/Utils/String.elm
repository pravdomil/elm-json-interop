module Utils.String exposing (..)

{-| -}


{-| To get letter from alphabet by number.
-}
letterByInt : Int -> String
letterByInt a =
    a + 97 |> Char.fromCode |> String.fromChar


{-| To convert first letter of string to upper case.
-}
firstToUpper : String -> String
firstToUpper a =
    a |> mapFirstLetter String.toUpper


{-| To convert first letter of string to lower case.
-}
firstToLower : String -> String
firstToLower a =
    a |> mapFirstLetter String.toLower


mapFirstLetter : (String -> String) -> String -> String
mapFirstLetter fn a =
    (a |> String.left 1 |> fn) ++ (a |> String.dropLeft 1)
