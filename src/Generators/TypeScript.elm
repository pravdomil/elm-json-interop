module Generators.TypeScript exposing (fromFileToTs)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordField, TypeAnnotation(..))
import String exposing (join)
import Utils exposing (getImports, toJsonString)


fromFileToTs : File -> String
fromFileToTs f =
    let
        root =
            "../" |> String.repeat ((Node.value f.moduleDefinition |> Module.moduleName |> List.length) - 1)
    in
    join "\n"
        [ "import { Maybe, Result } from \"" ++ root ++ "Basics/Basics\""
        , f.imports |> getImports (\n i -> "import { " ++ i ++ " } from \"" ++ root ++ (n |> join "/") ++ "\"") identity |> join "\n"
        , ""
        , List.filterMap fromDeclaration f.declarations |> join "\n\n\n"
        , ""
        ]


fromDeclaration : Node Declaration -> Maybe String
fromDeclaration (Node _ a) =
    case a of
        AliasDeclaration b ->
            Just <| fromTypeAlias b

        CustomTypeDeclaration b ->
            Just <| fromCustomType b

        _ ->
            Nothing


fromType : { a | documentation : Maybe (Node Documentation), name : Node String, generics : List (Node String) } -> String
fromType a =
    let
        declaration =
            "export type " ++ Node.value a.name ++ fromTypeGenerics a ++ " ="
    in
    fromDocumentation a.documentation ++ declaration


fromTypeGenerics : { a | generics : List (Node String) } -> String
fromTypeGenerics a =
    case a.generics of
        [] ->
            ""

        _ ->
            "<" ++ join ", " (List.map Node.value a.generics) ++ ">"


fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ " " ++ fromTypeAnnotation a.typeAnnotation


fromCustomType : Type -> String
fromCustomType a =
    let
        type_ =
            case ( String.split "JsRef" (Node.value a.name), a.constructors ) of
                ( _ :: t :: [], (Node _ { name }) :: [] ) ->
                    { a
                        | constructors =
                            [ Node emptyRange
                                (ValueConstructor name
                                    [ Node emptyRange (Typed (Node emptyRange ( [], t )) [])
                                    ]
                                )
                            ]
                    }

                _ ->
                    a

        constructors =
            join "\n  | " <| List.map fromCustomTypeConstructor type_.constructors
    in
    fromType type_ ++ "\n  | " ++ constructors ++ "\n\n" ++ fromCustomTypeConstants type_


fromCustomTypeConstants : Type -> String
fromCustomTypeConstants a =
    let
        mapGuard : Node ValueConstructor -> String
        mapGuard b =
            let
                tag =
                    Node.value <| .name <| Node.value <| b
            in
            "export const " ++ tag ++ " = " ++ toJsonString tag
    in
    join "\n" <| List.map mapGuard a.constructors


fromCustomTypeConstructor : Node ValueConstructor -> String
fromCustomTypeConstructor (Node _ a) =
    fromTuple (Node emptyRange (GenericType ("typeof " ++ Node.value a.name)) :: a.arguments)


fromDocumentation : Maybe (Node Documentation) -> String
fromDocumentation a =
    case a of
        Just (Node _ b) ->
            "/**" ++ String.slice 3 -2 b ++ " */\n"

        Nothing ->
            ""


fromTypeAnnotation : Node TypeAnnotation -> String
fromTypeAnnotation (Node _ a) =
    case a of
        GenericType b ->
            b

        Typed b c ->
            fromTyped b c

        Unit ->
            "[]"

        Tupled nodes ->
            fromTuple nodes

        Record b ->
            fromRecord b

        GenericRecord _ (Node _ b) ->
            fromRecord b

        FunctionTypeAnnotation _ _ ->
            "Function"


fromTyped : Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
fromTyped (Node _ ( name, str )) nodes =
    let
        generics =
            case nodes of
                [] ->
                    ""

                _ ->
                    "<" ++ (join ", " <| List.map fromTypeAnnotation nodes) ++ ">"

        fn =
            case name ++ [ str ] |> join "." of
                "Int" ->
                    "number"

                "Float" ->
                    "number"

                "Bool" ->
                    "boolean"

                "String" ->
                    "string"

                "Char" ->
                    "string"

                "List" ->
                    "Array"

                "Set" ->
                    "Array"

                "Dict" ->
                    "Record"

                "Encode.Value" ->
                    "unknown"

                "Decode.Value" ->
                    "unknown"

                a ->
                    a
    in
    fn ++ generics


fromTuple : List (Node TypeAnnotation) -> String
fromTuple a =
    "[" ++ (join ", " <| List.map fromTypeAnnotation a) ++ "]"


fromRecord : List (Node RecordField) -> String
fromRecord a =
    "{ " ++ (join "; " <| List.map fromRecordField a) ++ " }"


fromRecordField : Node RecordField -> String
fromRecordField (Node _ ( Node _ a, b )) =
    let
        maybeField =
            case Node.value b of
                Typed (Node _ ( _, "Maybe" )) _ ->
                    "?"

                _ ->
                    ""
    in
    a ++ maybeField ++ ": " ++ fromTypeAnnotation b
