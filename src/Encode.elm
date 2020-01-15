module Encode exposing (fromFileToEncoder)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import Utils exposing (Argument, argumentToString, stringFromAlphabet, toJsonString, tupleDestructor)


fromFileToEncoder : File -> String
fromFileToEncoder file =
    let
        name =
            String.join "." <| Module.moduleName <| Node.value file.moduleDefinition

        definitions =
            String.join "\n\n" <| List.filterMap fromDeclaration file.declarations
    in
    String.join "\n"
        [ "module " ++ name ++ ".Encode exposing (..)"
        , ""
        , "import " ++ name ++ " exposing (..)"
        , "import Json.Encode exposing (..)"
        , ""
        , "encodeMaybe a b = case b of\n   Just c -> a c\n   Nothing -> null"
        , "encodeDict _ b c = dict identity b c"
        , ""
        , definitions
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
        name =
            Node.value a.name

        signature =
            case List.isEmpty a.generics of
                True ->
                    "encode" ++ name ++ " : " ++ name ++ " -> Value\n"

                False ->
                    ""

        generics =
            case List.isEmpty a.generics of
                True ->
                    ""

                False ->
                    (++) " " <| String.join " " <| List.map (\(Node _ v) -> "t_" ++ v) a.generics

        declaration =
            "encode" ++ name ++ generics ++ " a = "
    in
    signature ++ declaration


fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ fromTypeAnnotation (Argument "" 0 False) a.typeAnnotation


fromCustomType : Type -> String
fromCustomType a =
    let
        cases =
            String.join "\n    " <| List.map fromCustomTypeConstructor a.constructors
    in
    fromType a ++ "\n  case a of\n    " ++ cases


fromCustomTypeConstructor : Node ValueConstructor -> String
fromCustomTypeConstructor (Node _ a) =
    let
        name =
            Node.value a.name

        params =
            case List.isEmpty a.arguments of
                True ->
                    ""

                False ->
                    " " ++ (String.join " " <| List.indexedMap (\b _ -> stringFromAlphabet (b + 1)) a.arguments)

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
    name ++ params ++ " -> " ++ fromRecord (Argument "" 1 False) [ Node emptyRange ( Node emptyRange name, Node emptyRange val ) ]


fromTypeAnnotation : Argument -> Node TypeAnnotation -> String
fromTypeAnnotation argument (Node r a) =
    case a of
        GenericType b ->
            "t_" ++ b ++ argumentToString argument

        Typed b c ->
            fromTyped argument b c

        Unit ->
            "list identity []"

        Tupled b ->
            case r == emptyRange of
                True ->
                    fromCustomTuple argument b

                False ->
                    fromTuple argument b

        Record b ->
            fromRecord argument b

        GenericRecord _ (Node _ b) ->
            fromRecord argument b

        FunctionTypeAnnotation _ _ ->
            "Debug.todo \"I don't know how to encode function.\""


fromTyped : Argument -> Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
fromTyped argument (Node _ ( name, str )) nodes =
    let
        generics =
            case List.isEmpty nodes of
                True ->
                    ""

                False ->
                    (++) " " <| String.join " " <| List.map (fromTypeAnnotation { argument | disabled = True }) nodes

        normalizedStr =
            case String.join "." (name ++ [ str ]) of
                "Int" ->
                    "int"

                "Float" ->
                    "float"

                "Bool" ->
                    "bool"

                "String" ->
                    "string"

                "List" ->
                    "list"

                "Array" ->
                    "list"

                "Set" ->
                    "set"

                "Encode.Value" ->
                    "identity"

                _ ->
                    String.join "." (name ++ [ "encode" ++ str ])
    in
    normalizedStr ++ generics ++ argumentToString argument


fromTuple : Argument -> List (Node TypeAnnotation) -> String
fromTuple argument a =
    let
        map i b =
            fromTypeAnnotation { argument | prefix = tupleDestructor (List.length a) i } b
    in
    "list identity [ " ++ (String.join ", " <| List.indexedMap map a) ++ " ]"


fromCustomTuple : Argument -> List (Node TypeAnnotation) -> String
fromCustomTuple argument a =
    let
        map i b =
            fromTypeAnnotation { argument | i = argument.i + i } b
    in
    "list identity [ " ++ (String.join ", " <| List.indexedMap map a) ++ " ]"


fromRecord : Argument -> RecordDefinition -> String
fromRecord argument a =
    "object [ " ++ (String.join ", " <| List.map (fromRecordField argument) a) ++ " ]"


fromRecordField : Argument -> Node RecordField -> String
fromRecordField argument (Node _ ( Node _ a, b )) =
    "( " ++ toJsonString a ++ ", " ++ fromTypeAnnotation argument b ++ " )"
