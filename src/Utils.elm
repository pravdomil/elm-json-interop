module Utils exposing (..)

import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module exposing (Module)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Json.Encode
import String exposing (join)


type alias Argument =
    { prefix : String, char : Int, suffix : String, disabled : Bool }


argumentToString : Argument -> String
argumentToString { prefix, char, suffix, disabled } =
    case disabled of
        True ->
            ""

        False ->
            " ( " ++ prefix ++ stringFromAlphabet char ++ suffix ++ " )"


toJsonString : String -> String
toJsonString a =
    Json.Encode.encode 0 (Json.Encode.string a)


stringFromAlphabet : Int -> String
stringFromAlphabet a =
    97 + a |> Char.fromCode |> String.fromChar


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


{-| To get list modules that needs to be imported.
-}
getImports : (ModuleName -> List String -> String) -> List (Node Import) -> List String
getImports toImport_ a =
    let
        filterModules : Node Import -> Maybe (Node Import)
        filterModules b =
            case b |> Node.value |> .moduleName |> Node.value of
                [ "Array" ] ->
                    Nothing

                [ "Set" ] ->
                    Nothing

                [ "Dict" ] ->
                    Nothing

                _ ->
                    Just b

        onlyExplicitImports : Node Import -> Maybe ( Node Import, List (Node TopLevelExpose) )
        onlyExplicitImports b =
            case b |> Node.value |> .exposingList of
                Just (Node _ (Explicit c)) ->
                    Just ( b, c )

                _ ->
                    Nothing

        toImport : ( Node Import, List (Node TopLevelExpose) ) -> Maybe String
        toImport ( Node _ b, c ) =
            case c |> List.filterMap filterExpose of
                [] ->
                    Nothing

                d ->
                    Just (toImport_ (Node.value b.moduleName) d)

        filterExpose : Node TopLevelExpose -> Maybe String
        filterExpose b =
            case b of
                TypeOrAliasExpose name ->
                    Just name

                TypeExpose { name } ->
                    Just name

                _ ->
                    Nothing
    in
    a
        |> List.filterMap
            (\v ->
                v
                    |> filterModules
                    |> Maybe.andThen onlyExplicitImports
                    |> Maybe.andThen toImport
            )


{-| To normalize record field name.
-}
normalizeRecordFieldName : String -> String
normalizeRecordFieldName a =
    let
        dropUnderscoreIfKeyword : String -> String
        dropUnderscoreIfKeyword v =
            if List.member (String.dropRight 1 v) elmKeywords then
                String.dropRight 1 v

            else
                v

        putUnderScoreToFront : String -> String
        putUnderScoreToFront v =
            if String.endsWith "_" v then
                "_" ++ String.dropRight 1 v

            else
                v
    in
    a |> dropUnderscoreIfKeyword |> putUnderScoreToFront


{-| To define what are reserved Elm keywords.
-}
elmKeywords : List String
elmKeywords =
    [ "module", "where", "import", "as", "exposing", "if", "then", "else", "case", "of", "let", "in", "type", "port", "infix" ]
