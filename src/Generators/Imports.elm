module Generators.Imports exposing (..)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.TypeAnnotation exposing (TypeAnnotation(..))


qualifyFile : File -> File
qualifyFile a =
    { a
        | declarations = a.declarations |> List.map (qualifyDeclaration a)
    }


qualifyDeclaration : File -> Node Declaration -> Node Declaration
qualifyDeclaration file a =
    Node.map
        (\v ->
            case v of
                FunctionDeclaration _ ->
                    v

                AliasDeclaration b ->
                    AliasDeclaration
                        { b
                            | typeAnnotation = b.typeAnnotation |> qualifyTypeAnnotation file
                        }

                CustomTypeDeclaration b ->
                    CustomTypeDeclaration
                        { b
                            | constructors =
                                b.constructors
                                    |> List.map
                                        (Node.map
                                            (\vv ->
                                                { vv
                                                    | arguments = vv.arguments |> List.map (qualifyTypeAnnotation file)
                                                }
                                            )
                                        )
                        }

                PortDeclaration _ ->
                    v

                InfixDeclaration _ ->
                    v

                Destructuring _ _ ->
                    v
        )
        a


qualifyTypeAnnotation : File -> Node TypeAnnotation -> Node TypeAnnotation
qualifyTypeAnnotation file a =
    let
        qualify_ : ( ModuleName, String ) -> ( ModuleName, String )
        qualify_ b =
            b
    in
    Node.map
        (\v ->
            case v of
                GenericType _ ->
                    v

                Typed b c ->
                    Typed
                        (b |> Node.map qualify_)
                        (c |> List.map (qualifyTypeAnnotation file))

                Unit ->
                    v

                Tupled b ->
                    Tupled (b |> List.map (qualifyTypeAnnotation file))

                Record b ->
                    Record (b |> List.map (Node.map (Tuple.mapSecond (qualifyTypeAnnotation file))))

                GenericRecord _ _ ->
                    v

                FunctionTypeAnnotation _ _ ->
                    v
        )
        a
