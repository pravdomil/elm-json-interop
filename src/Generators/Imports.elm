module Generators.Imports exposing (..)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
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
            case b of
                ( [], name ) ->
                    ( name |> qualifyName file |> Maybe.withDefault []
                    , name
                    )

                _ ->
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


qualifyName : File -> String -> Maybe ModuleName
qualifyName file a =
    let
        isImportExposing : Node Import -> Bool
        isImportExposing (Node _ b) =
            case b.exposingList of
                Just (Node _ c) ->
                    case c of
                        All _ ->
                            False

                        Explicit d ->
                            d |> List.any isExposeExposing

                Nothing ->
                    False

        isExposeExposing : Node TopLevelExpose -> Bool
        isExposeExposing (Node _ b) =
            case b of
                InfixExpose _ ->
                    False

                FunctionExpose _ ->
                    False

                TypeOrAliasExpose c ->
                    c == a

                TypeExpose c ->
                    c.name == a
    in
    file.imports
        |> List.filter isImportExposing
        |> List.head
        |> Maybe.map (Node.value >> .moduleName >> Node.value)
