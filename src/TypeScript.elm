module TypeScript exposing (fromFileToTs)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordField, TypeAnnotation(..))
import Utils exposing (toJsonString)


fromFileToTs : File -> String
fromFileToTs file =
    let
        definitions =
            [ "export type Maybe<a> = a | null" ]
                ++ List.filterMap fromDeclaration file.declarations
    in
    String.join "\n\n" definitions ++ "\n"


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
    case List.isEmpty a.generics of
        True ->
            ""

        False ->
            "<" ++ String.join ", " (List.map Node.value a.generics) ++ ">"


fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ " " ++ fromTypeAnnotation a.typeAnnotation


fromCustomType : Type -> String
fromCustomType a =
    let
        constructors =
            String.join "\n  | " <| List.map fromCustomTypeConstructor a.constructors
    in
    fromType a ++ "\n  | " ++ constructors ++ "\n\n" ++ fromCustomTypeGuards a


fromCustomTypeGuards : Type -> String
fromCustomTypeGuards a =
    let
        generics =
            fromTypeGenerics a

        mapGuard : Node ValueConstructor -> String
        mapGuard b =
            let
                tag =
                    Node.value <| .name <| Node.value b
            in
            "export const is"
                ++ tag
                ++ " = "
                ++ generics
                ++ "(a: "
                ++ Node.value a.name
                ++ generics
                ++ "): a is "
                ++ fromCustomTypeConstructor b
                ++ " => "
                ++ toJsonString tag
                ++ " in a"
    in
    String.join "\n" <| List.map mapGuard a.constructors


fromCustomTypeConstructor : Node ValueConstructor -> String
fromCustomTypeConstructor (Node _ a) =
    let
        record : RecordField
        record =
            ( a.name, Node emptyRange <| Tupled a.arguments )
    in
    fromRecord [ Node emptyRange record ]


fromDocumentation : Maybe (Node Documentation) -> String
fromDocumentation a =
    case a of
        Just (Node _ b) ->
            "/**" ++ String.slice 3 -2 b ++ "*/\n"

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
            case List.isEmpty nodes of
                True ->
                    ""

                False ->
                    "<" ++ (String.join ", " <| List.map fromTypeAnnotation nodes) ++ ">"

        normalizedStr =
            case String.join "." (name ++ [ str ]) of
                "Int" ->
                    "number"

                "Float" ->
                    "number"

                "Bool" ->
                    "boolean"

                "String" ->
                    "string"

                "List" ->
                    "Array"

                "Set" ->
                    "Array"

                "Dict" ->
                    "Record"

                "Encode.Value" ->
                    "unknown"

                a ->
                    a
    in
    normalizedStr ++ generics


fromTuple : List (Node TypeAnnotation) -> String
fromTuple a =
    "[" ++ (String.join ", " <| List.map fromTypeAnnotation a) ++ "]"


fromRecord : List (Node RecordField) -> String
fromRecord a =
    "{ " ++ (String.join ", " <| List.map fromRecordField a) ++ " }"


fromRecordField : Node RecordField -> String
fromRecordField (Node _ ( Node _ a, b )) =
    a ++ ": " ++ fromTypeAnnotation b
