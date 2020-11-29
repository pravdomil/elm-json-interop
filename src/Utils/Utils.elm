module Utils.Utils exposing (..)

import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Json.Encode as Encode
import Regex
import String exposing (join)


{-| To encode string into JSON string.
-}
encodeJsonString : String -> String
encodeJsonString a =
    Encode.string a |> Encode.encode 0


{-| To get letter from alphabet by number.
-}
letterByInt : Int -> String
letterByInt a =
    a + 97 |> Char.fromCode |> String.fromChar


{-| To get module name from file.
-}
fileToModuleName : File -> String
fileToModuleName a =
    Node.value a.moduleDefinition |> Module.moduleName |> moduleNameToString


{-| To get string from module name.
-}
moduleNameToString : ModuleName -> String
moduleNameToString a =
    a |> join "."


{-| To denormalize record field name.
-}
denormalizeRecordFieldName : String -> String
denormalizeRecordFieldName a =
    let
        putUnderscoresToStart : String -> String
        putUnderscoresToStart b =
            b
                |> Regex.replace (Regex.fromString "^(.*?)(_*)$" |> Maybe.withDefault Regex.never)
                    (\c ->
                        case c.submatches of
                            [ Just d, Just e ] ->
                                e ++ d

                            _ ->
                                b
                    )

        unescapeKeywords : String -> String
        unescapeKeywords b =
            elmKeywords
                |> List.foldl
                    (\c acc -> acc |> swap (c ++ "_") c |> swap (c ++ "__") (c ++ "_"))
                    b
    in
    a |> unescapeKeywords |> putUnderscoresToStart


{-| -}
swap : a -> a -> a -> a
swap a b c =
    if a == c then
        b

    else
        c


{-| To define what are reserved Elm keywords.
-}
elmKeywords : List String
elmKeywords =
    [ "module", "where", "import", "as", "exposing", "if", "then", "else", "case", "of", "let", "in", "type", "port", "infix" ]


{-| To wrap string in parentheses.
-}
wrapInParentheses : String -> String
wrapInParentheses a =
    "(" ++ a ++ ")"


{-| To do simple regular expression replace.
-}
regexReplace : String -> (String -> String) -> String -> String
regexReplace regex replacement a =
    a
        |> Regex.replace
            (regex |> Regex.fromString |> Maybe.withDefault Regex.never)
            (.match >> replacement)


{-| -}
maybeCustomTypeHasCustomTags : File -> Type -> Maybe (List ( String, Node ValueConstructor ))
maybeCustomTypeHasCustomTags file a =
    let
        oneArgument : Node ValueConstructor -> Maybe ()
        oneArgument b =
            if (b |> Node.value |> .arguments |> List.length) == 1 then
                Just ()

            else
                Nothing

        commentAtSameLine : Node a -> Maybe String
        commentAtSameLine b =
            file.comments
                |> List.filter
                    (\c ->
                        (c |> Node.range |> .start |> .row) == (b |> Node.range |> .start |> .row)
                    )
                |> List.head
                |> Maybe.map (\v -> v |> Node.value |> String.slice 3 -3)
    in
    a.constructors
        |> List.foldl
            (\b acc ->
                Maybe.andThen
                    (\c ->
                        Maybe.map2
                            (\_ e ->
                                c ++ [ ( e, b ) ]
                            )
                            (oneArgument b)
                            (commentAtSameLine b)
                    )
                    acc
            )
            (Just [])


{-| To convert first letter of string to lower case.
-}
firstToLowerCase : String -> String
firstToLowerCase a =
    case String.toList a of
        first :: rest ->
            String.fromList (Char.toLower first :: rest)

        _ ->
            a
