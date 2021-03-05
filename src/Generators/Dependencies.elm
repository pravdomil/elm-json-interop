module Generators.Dependencies exposing (..)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Expression exposing (Expression(..), Function, LetDeclaration(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node)


fromFile : File -> List ( ModuleName, String )
fromFile a =
    a.declarations |> List.concatMap fromDeclaration


fromDeclaration : Node Declaration -> List ( ModuleName, String )
fromDeclaration a =
    case Node.value a of
        FunctionDeclaration b ->
            b.declaration |> Node.value |> .expression |> fromExpression

        AliasDeclaration _ ->
            []

        CustomTypeDeclaration _ ->
            []

        PortDeclaration _ ->
            []

        InfixDeclaration _ ->
            []

        Destructuring _ _ ->
            []


fromExpression : Node Expression -> List ( ModuleName, String )
fromExpression a =
    case Node.value a of
        UnitExpr ->
            []

        Application b ->
            b |> List.concatMap fromExpression

        OperatorApplication _ _ b c ->
            fromExpression b ++ fromExpression c

        FunctionOrValue b c ->
            [ ( b, c ) ]

        IfBlock b c d ->
            fromExpression b ++ fromExpression c ++ fromExpression d

        PrefixOperator _ ->
            []

        Operator _ ->
            []

        Integer _ ->
            []

        Hex _ ->
            []

        Floatable _ ->
            []

        Negation b ->
            b |> fromExpression

        Literal _ ->
            []

        CharLiteral _ ->
            []

        TupledExpression b ->
            b |> List.concatMap fromExpression

        ParenthesizedExpression b ->
            b |> fromExpression

        LetExpression b ->
            fromExpression b.expression
                ++ (b.declarations
                        |> List.concatMap
                            (\v ->
                                case v |> Node.value of
                                    LetFunction c ->
                                        c.declaration |> Node.value |> .expression |> fromExpression

                                    LetDestructuring _ c ->
                                        c |> fromExpression
                            )
                   )

        CaseExpression b ->
            fromExpression b.expression
                ++ (b.cases |> List.concatMap (Tuple.second >> fromExpression))

        LambdaExpression b ->
            b.expression |> fromExpression

        RecordExpr b ->
            b |> List.concatMap (Node.value >> Tuple.second >> fromExpression)

        ListExpr b ->
            b |> List.concatMap fromExpression

        RecordAccess b _ ->
            b |> fromExpression

        RecordAccessFunction _ ->
            []

        RecordUpdateExpression _ b ->
            b |> List.concatMap (Node.value >> Tuple.second >> fromExpression)

        GLSLExpression _ ->
            []
