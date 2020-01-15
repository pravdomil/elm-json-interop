module Decode exposing (fromFileToDecoder)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Module as Module
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import Utils exposing (Prefix, mapFn, prefixToString, stringFromAlphabet, toJsonString, tupleConstructor)


fromFileToDecoder : File -> String
fromFileToDecoder file =
    let
        name =
            String.join "." <| Module.moduleName <| Node.value file.moduleDefinition

        definitions =
            String.join "\n\n" <| List.filterMap fromDeclaration file.declarations
    in
    String.join "\n"
        [ "module " ++ name ++ ".Decode exposing (..)"
        , ""
        , "import " ++ name ++ " exposing (..)"
        , "import Json.Decode exposing (..)"
        , "import Set"
        , ""
        , "decodeSet a = map Set.fromList (list a)"
        , ""
        , "decodeDict _ a = dict a"
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
                    "decode" ++ name ++ " : Decoder " ++ name ++ "\n"

                False ->
                    ""

        generics =
            case List.isEmpty a.generics of
                True ->
                    ""

                False ->
                    (++) " " <| String.join " " <| List.map (\(Node _ v) -> "t_" ++ v) a.generics

        declaration =
            "decode" ++ name ++ generics ++ " = "
    in
    signature ++ declaration


fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ fromTypeAnnotation (Prefix "") a.typeAnnotation


fromCustomType : Type -> String
fromCustomType a =
    let
        cases =
            String.join "\n    , " <| List.map fromCustomTypeConstructor a.constructors
    in
    fromType a ++ "\n  oneOf\n    [ " ++ cases ++ "\n    ]"


fromCustomTypeConstructor : Node ValueConstructor -> String
fromCustomTypeConstructor (Node _ a) =
    let
        name =
            Node.value a.name

        len =
            List.length a.arguments

        val =
            case List.length a.arguments of
                0 ->
                    "succeed " ++ name

                _ ->
                    mapFn len ++ " " ++ name ++ " " ++ (String.join " " <| List.map (fromTypeAnnotation (Prefix "")) a.arguments)
    in
    "field " ++ toJsonString name ++ " (" ++ val ++ ")"


fromTypeAnnotation : Prefix -> Node TypeAnnotation -> String
fromTypeAnnotation argument (Node _ a) =
    let
        result =
            case a of
                GenericType b ->
                    "t_" ++ b ++ prefixToString argument

                Typed b c ->
                    fromTyped argument b c

                Unit ->
                    "succeed ()"

                Tupled nodes ->
                    fromTuple argument nodes

                Record b ->
                    fromRecord argument b

                GenericRecord _ (Node _ b) ->
                    fromRecord argument b

                FunctionTypeAnnotation _ _ ->
                    "Debug.todo \"I don't know how to decode function.\""
    in
    "(" ++ result ++ ")"


fromTyped : Prefix -> Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
fromTyped argument (Node _ ( name, str )) nodes =
    let
        generics =
            case List.isEmpty nodes of
                True ->
                    ""

                False ->
                    (++) " " <| String.join " " <| List.map (fromTypeAnnotation argument) nodes

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

                "Maybe" ->
                    "maybe"

                "Encode.Value" ->
                    "value"

                _ ->
                    String.join "." (name ++ [ "decode" ++ str ])
    in
    normalizedStr ++ generics


fromTuple : Prefix -> List (Node TypeAnnotation) -> String
fromTuple argument a =
    let
        len =
            List.length a

        tup =
            List.map (fromTypeAnnotation argument) a
    in
    mapFn len ++ " " ++ tupleConstructor len ++ " " ++ String.join " " tup


fromRecord : Prefix -> RecordDefinition -> String
fromRecord argument a =
    let
        len =
            List.length a

        args =
            List.indexedMap (\i _ -> stringFromAlphabet i) a

        fields =
            List.indexedMap (\i (Node _ ( Node _ b, _ )) -> b ++ " = " ++ stringFromAlphabet i) a

        lambda =
            "(\\" ++ String.join " " args ++ " -> { " ++ String.join ", " fields ++ " })"
    in
    mapFn len ++ " " ++ lambda ++ " " ++ (String.join " " <| List.map (fromRecordField argument) a)


fromRecordField : Prefix -> Node RecordField -> String
fromRecordField argument (Node _ ( Node _ a, b )) =
    "(field " ++ toJsonString a ++ " " ++ fromTypeAnnotation argument b ++ ")"
