module Generators.TypeScriptDeclaration exposing (fromFile)

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
import Utils.Utils exposing (encodeJsonString, moduleImports, denormalizeRecordFieldName)


{-| To get TypeScript declaration from file.
-}
fromFile : File -> String
fromFile a =
    let
        root : String
        root =
            "../" |> String.repeat ((Node.value a.moduleDefinition |> Module.moduleName |> List.length) - 1)
    in
    [ "import { Maybe, Result } from \"../" ++ root ++ "Basics/Basics\""
    , a.imports
        |> moduleImports
            (\v vv ->
                "import { " ++ (vv |> join ", ") ++ " } from \"" ++ root ++ (v |> join "/") ++ "\""
            )
        |> join "\n"
    , ""
    , a.declarations |> List.filterMap declarationToTs |> join "\n\n\n"
    , ""
    ]
        |> join "\n"


{-| To get TypeScript from declaration.
-}
declarationToTs : Node Declaration -> Maybe String
declarationToTs a =
    case a |> Node.value of
        AliasDeclaration b ->
            Just (typeAliasToTs b)

        CustomTypeDeclaration b ->
            Just (customTypeToTs b)

        _ ->
            Nothing


{-| To get TypeScript from type alias.
-}
typeAliasToTs : TypeAlias -> String
typeAliasToTs a =
    typeToTs a ++ " " ++ typeAnnotationToTs a.typeAnnotation


{-| To get TypeScript from custom type.
-}
customTypeToTs : Type -> String
customTypeToTs a =
    let
        jsRef : Maybe String
        jsRef =
            case a.name |> Node.value |> String.split "JsRef" of
                _ :: b :: [] ->
                    Just b

                _ ->
                    Nothing

        oneConstructor : Maybe (Node String)
        oneConstructor =
            case a.constructors of
                (Node _ { name }) :: [] ->
                    Just name

                _ ->
                    Nothing

        type_ : Type
        type_ =
            case ( jsRef, oneConstructor ) of
                ( Just t, Just name ) ->
                    { a | constructors = [ newConstructor name t ] }

                _ ->
                    a

        newConstructor : Node String -> String -> Node ValueConstructor
        newConstructor name t =
            Node emptyRange
                (ValueConstructor name
                    [ Node emptyRange (Typed (Node emptyRange ( [], t )) [])
                    ]
                )

        constructors : String
        constructors =
            type_.constructors |> List.map customTypeConstructorToTs |> join "\n  | "
    in
    typeToTs type_ ++ "\n  | " ++ constructors ++ "\n\n" ++ customTypeTagToTs type_


{-| To get TypeScript from custom type tag.
-}
customTypeTagToTs : Type -> String
customTypeTagToTs a =
    let
        toTagNameConstant : Node ValueConstructor -> String
        toTagNameConstant b =
            let
                tag : String
                tag =
                    b |> Node.value |> .name |> Node.value
            in
            "export const " ++ tag ++ " = " ++ encodeJsonString tag
    in
    a.constructors |> List.map toTagNameConstant |> join "\n"


{-| To get TypeScript from custom type constructor.
-}
customTypeConstructorToTs : Node ValueConstructor -> String
customTypeConstructorToTs (Node _ a) =
    Node emptyRange (GenericType ("typeof " ++ Node.value a.name)) :: a.arguments |> tupleToTs


{-| To get TypeScript from type.
-}
typeToTs : { a | documentation : Maybe (Node Documentation), name : Node String, generics : List (Node String) } -> String
typeToTs a =
    let
        documentation : String
        documentation =
            case a.documentation of
                Just (Node _ b) ->
                    "/**" ++ String.slice 3 -2 b ++ " */\n"

                Nothing ->
                    ""

        declaration : String
        declaration =
            "export type " ++ Node.value a.name ++ generics ++ " ="

        generics : String
        generics =
            case a.generics of
                [] ->
                    ""

                _ ->
                    "<" ++ join ", " (List.map Node.value a.generics) ++ ">"
    in
    documentation ++ declaration


{-| To get TypeScript from type annotation.
-}
typeAnnotationToTs : Node TypeAnnotation -> String
typeAnnotationToTs a =
    case a |> Node.value of
        GenericType b ->
            b

        Typed b c ->
            typedToTs b c

        Unit ->
            "[]"

        Tupled nodes ->
            tupleToTs nodes

        Record b ->
            recordToTs b

        GenericRecord _ (Node _ b) ->
            recordToTs b

        FunctionTypeAnnotation _ _ ->
            "Function"


{-| To get TypeScript from typed.
-}
typedToTs : Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
typedToTs (Node _ ( moduleName, name )) arguments =
    let
        fn : String
        fn =
            case moduleName ++ [ name ] |> join "." of
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

        generics : String
        generics =
            case arguments of
                [] ->
                    ""

                _ ->
                    "<" ++ (arguments |> List.map typeAnnotationToTs |> join ", ") ++ ">"
    in
    fn ++ generics


{-| To get TypeScript from tuple.
-}
tupleToTs : List (Node TypeAnnotation) -> String
tupleToTs a =
    "[" ++ (a |> List.map typeAnnotationToTs |> join ", ") ++ "]"


{-| To get TypeScript from record.
-}
recordToTs : List (Node RecordField) -> String
recordToTs a =
    "{ " ++ (a |> List.map recordFieldToTs |> join "; ") ++ " }"


{-| To get TypeScript from record field.
-}
recordFieldToTs : Node RecordField -> String
recordFieldToTs (Node _ ( Node _ a, b )) =
    let
        maybeField : String
        maybeField =
            case b |> Node.value of
                Typed (Node _ ( _, "Maybe" )) _ ->
                    "?"

                _ ->
                    ""
    in
    denormalizeRecordFieldName a ++ maybeField ++ ": " ++ typeAnnotationToTs b
