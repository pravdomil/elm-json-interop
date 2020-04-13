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


moduleNameFromFile : File -> String
moduleNameFromFile f =
    Node.value f.moduleDefinition |> Module.moduleName |> join "."


moduleNameToString : ModuleName -> String
moduleNameToString n =
    n |> join "."


getImports : (ModuleName -> String -> String) -> (String -> String) -> List (Node Import) -> List String
getImports toImport_ toName i =
    let
        toImport : Node Import -> Maybe String
        toImport (Node _ ii) =
            case ( ii.moduleName, ii.exposingList ) of
                ( Node _ [ "Array" ], _ ) ->
                    Nothing

                ( Node _ [ "Set" ], _ ) ->
                    Nothing

                ( Node _ [ "Dict" ], _ ) ->
                    Nothing

                ( _, Just (Node _ (Explicit e)) ) ->
                    let
                        imports : String
                        imports =
                            e |> List.filterMap toExpose |> join ", "

                        toExpose : Node TopLevelExpose -> Maybe String
                        toExpose (Node _ ee) =
                            case ee of
                                TypeOrAliasExpose name ->
                                    Just (toName name)

                                TypeExpose { name } ->
                                    Just (toName name)

                                _ ->
                                    Nothing
                    in
                    Just (toImport_ (Node.value ii.moduleName) imports)

                _ ->
                    Nothing
    in
    i |> List.filterMap toImport
