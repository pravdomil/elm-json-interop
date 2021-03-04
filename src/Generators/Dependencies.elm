module Generators.Dependencies exposing (..)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))


fromFile : File -> List ( ModuleName, String )
fromFile a =
    a.declarations |> List.concatMap fromDeclaration


fromDeclaration : Node Declaration -> List ( ModuleName, String )
fromDeclaration a =
    case Node.value a of
        FunctionDeclaration _ ->
            []

        AliasDeclaration b ->
            b.typeAnnotation |> fromTypeAnnotation

        CustomTypeDeclaration b ->
            b.constructors |> List.concatMap (Node.value >> .arguments >> List.concatMap fromTypeAnnotation)

        PortDeclaration _ ->
            []

        InfixDeclaration _ ->
            []

        Destructuring _ _ ->
            []


fromTypeAnnotation : Node TypeAnnotation -> List ( ModuleName, String )
fromTypeAnnotation a =
    case Node.value a of
        GenericType _ ->
            []

        Typed b c ->
            (b |> Node.value) :: (c |> List.concatMap fromTypeAnnotation)

        Unit ->
            []

        Tupled b ->
            b |> List.concatMap fromTypeAnnotation

        Record b ->
            b |> List.concatMap (Node.value >> Tuple.second >> fromTypeAnnotation)

        GenericRecord _ _ ->
            []

        FunctionTypeAnnotation _ _ ->
            []
