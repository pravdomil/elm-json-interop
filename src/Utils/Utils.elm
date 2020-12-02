module Utils.Utils exposing (..)

import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.Node as Node exposing (Node(..))
import Json.Encode as Encode
import Regex
import String exposing (join)


{-| To get module name from file.
-}
fileToModuleName : File -> String
fileToModuleName a =
    Node.value a.moduleDefinition |> Module.moduleName |> join "."


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
    case String.toList a of
        first :: rest ->
            String.fromList (Char.toUpper first :: rest)

        _ ->
            a


{-| To convert first letter of string to lower case.
-}
firstToLower : String -> String
firstToLower a =
    case String.toList a of
        first :: rest ->
            String.fromList (Char.toLower first :: rest)

        _ ->
            a



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
