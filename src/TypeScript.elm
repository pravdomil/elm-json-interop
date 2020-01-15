module TypeScript exposing (fromFileToTs)

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


fromFileToTs : File -> String
fromFileToTs file =
    let
        name =
            String.join "." <| Module.moduleName <| Node.value file.moduleDefinition

        definitions =
            String.join "\n" <|
                List.map ((++) "  ") <|
                    String.split "\n" <|
                        String.join "\n\n" <|
                            List.filterMap fromDeclaration file.declarations
    in
    String.join "\n"
        [ "export namespace " ++ name ++ " {"
        , "  export type Maybe<a> = a | null"
        , "  "
        , definitions
        , "}"
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
        generics =
            case List.isEmpty a.generics of
                True ->
                    ""

                False ->
                    "<" ++ String.join ", " (List.map Node.value a.generics) ++ ">"

        declaration =
            "export type " ++ Node.value a.name ++ generics ++ " = "
    in
    fromDocumentation a.documentation ++ declaration


fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ fromTypeAnnotation a.typeAnnotation


fromCustomType : Type -> String
fromCustomType a =
    fromType a ++ (String.join " | " <| List.map fromCustomTypeConstructor a.constructors)


fromCustomTypeConstructor : Node ValueConstructor -> String
fromCustomTypeConstructor (Node _ a) =
    let
        name : String
        name =
            Node.value a.name

        val : TypeAnnotation
        val =
            case List.length a.arguments of
                0 ->
                    Unit

                1 ->
                    case List.head a.arguments of
                        Just b ->
                            Node.value b

                        Nothing ->
                            Unit

                _ ->
                    Tupled a.arguments
    in
    fromRecord [ Node emptyRange ( Node emptyRange name, Node emptyRange val ) ]


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
                    "any"

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
