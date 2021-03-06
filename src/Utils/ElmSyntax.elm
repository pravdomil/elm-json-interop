module Utils.ElmSyntax exposing (..)

import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Node exposing (Node(..))
import Elm.Syntax.Range as Range
import Elm.Syntax.Type exposing (Type)
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))
import Elm.Writer as Writer


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


application : List (Node Expression) -> Expression
application a =
    a |> List.map (ParenthesizedExpression >> n) |> Application


oneConstructorAndOneArgument : Type -> Maybe ( Node String, Node TypeAnnotation )
oneConstructorAndOneArgument a =
    a.constructors
        |> listSingleton
        |> Maybe.andThen
            (\(Node _ v) ->
                v.arguments |> listSingleton |> Maybe.map (Tuple.pair v.name)
            )


listSingleton : List a -> Maybe a
listSingleton a =
    case a of
        b :: [] ->
            Just b

        _ ->
            Nothing


writeFile : File -> String
writeFile a =
    a
        |> Writer.writeFile
        |> Writer.write
        |> String.lines
        |> (\v ->
                List.take 1 v ++ [ "\n{-| Generated by <https://github.com/pravdomil/Elm-JSON-Interop>.\n-}\n" ] ++ List.drop 1 v
           )
        |> String.join "\n"


n : a -> Node a
n =
    Node Range.emptyRange
