module Utils.ElmSyntax exposing (..)

import Elm.Syntax.Node exposing (Node(..))
import Elm.Syntax.Range as Range
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))


function : List (Node TypeAnnotation) -> Node TypeAnnotation
function a =
    let
        helper : List (Node TypeAnnotation) -> Node TypeAnnotation -> Node TypeAnnotation
        helper b c =
            b |> List.foldl (\v acc -> FunctionTypeAnnotation v acc |> n) c
    in
    case a |> List.reverse of
        [] ->
            n Unit

        b :: [] ->
            b

        b :: c :: rest ->
            FunctionTypeAnnotation c b |> n |> helper rest


n : a -> Node a
n =
    Node Range.emptyRange
