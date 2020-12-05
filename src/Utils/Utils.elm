module Utils.Utils exposing (..)

import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node(..))
import Json.Encode as Encode
import Regex
import String exposing (join)


{-| To get module name from file.
-}
fileToModuleName : File -> List String
fileToModuleName a =
    Node.value a.moduleDefinition |> Module.moduleName


{-| To wrap string in parentheses.
-}
wrapInParentheses : String -> String
wrapInParentheses a =
    "(" ++ a ++ ")"



--


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


{-| -}
mapFirstLetter : (String -> String) -> String -> String
mapFirstLetter fn a =
    (a |> String.slice 0 1 |> fn) ++ (a |> String.dropLeft 1)



--


{-| To encode string into JSON string.
-}
toJsonString : String -> String
toJsonString a =
    Encode.string a |> Encode.encode 0



--


{-| To do simple regular expression replace.
-}
regexReplace : String -> (String -> String) -> String -> String
regexReplace regex replacement a =
    a
        |> Regex.replace
            (regex |> Regex.fromString |> Maybe.withDefault Regex.never)
            (.match >> replacement)



--


{-| -}
dropLast : List a -> List a
dropLast a =
    a |> List.reverse |> List.drop 1 |> List.reverse



--


{-| -}
toFunctionName : String -> String
toFunctionName a =
    if elmKeywords |> List.member a then
        firstToLower a ++ "_"

    else
        firstToLower a


{-| To define what are reserved Elm keywords.
-}
elmKeywords : List String
elmKeywords =
    [ "module", "where", "import", "as", "exposing", "if", "then", "else", "case", "of", "let", "in", "type", "port", "infix" ]
