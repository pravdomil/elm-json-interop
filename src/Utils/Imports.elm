module Utils.Imports exposing (..)

import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Node as Node exposing (Node(..))
import Utils.Utils exposing (dropLast, firstToLower)


fromList : String -> List (Node Import) -> String
fromList suffix a =
    a
        |> List.filter shouldImport
        |> List.filterMap (fromImport suffix)
        |> String.join "\n"


fromImport : String -> Node Import -> Maybe String
fromImport suffix (Node _ a) =
    if a.moduleName |> Node.value |> List.length |> (==) 1 then
        Nothing

    else
        [ "import"
        , " "
        , ((a.moduleName |> Node.value |> dropLast) ++ [ suffix ]) |> String.join "."
        , " "
        , a.moduleAlias
            |> Maybe.withDefault a.moduleName
            |> (\v -> "as " ++ (v |> Node.value |> String.join "_"))
        , a.exposingList
            |> Maybe.map fromExposing
            |> Maybe.withDefault ""
        ]
            |> String.join ""
            |> Just


fromExposing : Node Exposing -> String
fromExposing a =
    case a |> Node.value of
        All _ ->
            " exposing (..)"

        Explicit b ->
            case b |> List.filterMap fromTopLevelExpose of
                [] ->
                    ""

                c ->
                    " exposing (" ++ (c |> String.join ", ") ++ ")"


fromTopLevelExpose : Node TopLevelExpose -> Maybe String
fromTopLevelExpose a =
    (case a |> Node.value of
        TypeOrAliasExpose name ->
            Just name

        TypeExpose { name } ->
            Just name

        _ ->
            Nothing
    )
        |> Maybe.map firstToLower


shouldImport : Node Import -> Bool
shouldImport b =
    case b |> Node.value |> .moduleName |> Node.value of
        [ "Array" ] ->
            False

        [ "Set" ] ->
            False

        [ "Dict" ] ->
            False

        [ "Json", "Decode" ] ->
            False

        [ "Json", "Encode" ] ->
            False

        [ "Utils", "Json", "Decode_" ] ->
            False

        [ "Utils", "Json", "Encode_" ] ->
            False

        _ ->
            True
