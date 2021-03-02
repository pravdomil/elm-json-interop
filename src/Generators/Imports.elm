module Generators.Imports exposing (..)

import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range as Range
import Utils.String_ as String_


fromFile : String -> File -> List (Node Import)
fromFile suffix a =
    a.imports
        |> List.filter shouldImport
        |> List.map (changeImport suffix)


changeImport : String -> Node Import -> Node Import
changeImport suffix a =
    let
        map : Import -> Import
        map b =
            { b
                | moduleName = b.moduleName |> Node.map (\v -> v ++ [ suffix ])
                , moduleAlias = b.moduleAlias |> Maybe.withDefault b.moduleName |> Node.value |> String.join "_" |> List.singleton |> n |> Just
                , exposingList = b.exposingList |> Maybe.map changeExposing
            }
    in
    a |> Node.map map


changeExposing : Node Exposing -> Node Exposing
changeExposing a =
    let
        map : Exposing -> Exposing
        map b =
            case b of
                All c ->
                    All c

                Explicit c ->
                    Explicit (c |> List.filterMap changeTopLevelExpose)
    in
    a |> Node.map map


changeTopLevelExpose : Node TopLevelExpose -> Maybe (Node TopLevelExpose)
changeTopLevelExpose a =
    case a |> Node.value of
        TypeOrAliasExpose name ->
            Just (a |> Node.map (\_ -> FunctionExpose (String_.firstToLower name)))

        TypeExpose { name } ->
            Just (a |> Node.map (\_ -> FunctionExpose (String_.firstToLower name)))

        _ ->
            Nothing


shouldImport : Node Import -> Bool
shouldImport a =
    case a |> Node.value |> .moduleName |> Node.value of
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



--


n : a -> Node a
n =
    Node Range.emptyRange
