module Generators.Decode exposing (fromFileToDecoder)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import String exposing (join)
import Utils exposing (Prefix, mapFn, moduleName, prefixToString, stringFromAlphabet, toJsonString, tupleConstructor)


fromFileToDecoder : File -> String
fromFileToDecoder f =
    let
        definitions =
            join "\n\n" <| List.filterMap fromDeclaration f.declarations
    in
    join "\n"
        [ "module Interop." ++ moduleName f ++ "Decode exposing (..)"
        , ""
        , "import " ++ moduleName f ++ " as A"
        , "import Json.Decode exposing (..)"
        , "import Set"
        , ""
        , "setDecoder a = map Set.fromList (list a)"
        , ""
        , "dictDecoder _ a = dict a"
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
            case a.generics of
                [] ->
                    decoderName name ++ " : Decoder A." ++ name ++ "\n"

                _ ->
                    ""

        generics =
            case a.generics of
                [] ->
                    ""

                _ ->
                    (++) " " <| join " " <| List.map (\(Node _ v) -> "t_" ++ v) a.generics

        declaration =
            decoderName name ++ generics ++ " ="
    in
    signature ++ declaration


fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ " " ++ fromTypeAnnotation (Prefix "") a.typeAnnotation


fromCustomType : Type -> String
fromCustomType a =
    let
        cases =
            join "\n    , " <| List.map fromCustomTypeConstructor a.constructors
    in
    fromType a ++ "\n  oneOf\n    [ " ++ cases ++ "\n    ]"


fromCustomTypeConstructor : Node ValueConstructor -> String
fromCustomTypeConstructor (Node _ a) =
    let
        name =
            "A." ++ Node.value a.name

        len =
            List.length a.arguments

        tup =
            List.indexedMap (tupleMap (Prefix "") 0) a.arguments

        val =
            case a.arguments of
                [] ->
                    "succeed " ++ name

                b :: [] ->
                    "map " ++ name ++ " " ++ fromTypeAnnotation (Prefix "") b

                _ ->
                    mapFn len ++ " " ++ name ++ " " ++ join " " tup
    in
    "field " ++ toJsonString (Node.value a.name) ++ " (" ++ val ++ ")"


fromTypeAnnotation : Prefix -> Node TypeAnnotation -> String
fromTypeAnnotation prefix (Node _ a) =
    let
        result =
            case a of
                GenericType b ->
                    "t_" ++ b ++ prefixToString prefix

                Typed b c ->
                    fromTyped prefix b c

                Unit ->
                    "succeed ()"

                Tupled nodes ->
                    fromTuple prefix nodes

                Record b ->
                    fromRecord prefix b

                GenericRecord _ (Node _ b) ->
                    fromRecord prefix b

                FunctionTypeAnnotation _ _ ->
                    "Debug.todo \"I don't know how to decode function.\""
    in
    "(" ++ result ++ ")"


fromTyped : Prefix -> Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
fromTyped prefix (Node _ ( name, str )) nodes =
    let
        generics =
            case nodes of
                [] ->
                    ""

                _ ->
                    (++) " " <| join " " <| List.map (fromTypeAnnotation prefix) nodes

        fn =
            case name ++ [ str ] |> join "." of
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
                    name ++ [ decoderName str ] |> join "."
    in
    fn ++ generics


fromTuple : Prefix -> List (Node TypeAnnotation) -> String
fromTuple prefix a =
    let
        len =
            List.length a

        tup =
            List.indexedMap (tupleMap prefix 0) a
    in
    mapFn len ++ " " ++ tupleConstructor len ++ " " ++ join " " tup


tupleMap : Prefix -> Int -> Int -> Node TypeAnnotation -> String
tupleMap prefix offset i a =
    "(index " ++ String.fromInt (offset + i) ++ " " ++ fromTypeAnnotation prefix a ++ ")"


fromRecord : Prefix -> RecordDefinition -> String
fromRecord prefix a =
    let
        len =
            List.length a

        args =
            List.indexedMap (\i _ -> stringFromAlphabet i) a

        fields =
            List.indexedMap (\i (Node _ ( Node _ b, _ )) -> b ++ " = " ++ stringFromAlphabet i) a

        lambda =
            "(\\" ++ join " " args ++ " -> { " ++ join ", " fields ++ " })"
    in
    mapFn len ++ " " ++ lambda ++ " " ++ (join " " <| List.map (fromRecordField prefix) a)


fromRecordField : Prefix -> Node RecordField -> String
fromRecordField prefix (Node _ ( Node _ a, b )) =
    let
        maybeField =
            case Node.value b of
                Typed (Node _ ( _, "Maybe" )) _ ->
                    "(\\maybeField -> oneOf [ maybeField, succeed Nothing ]) <| "

                _ ->
                    ""
    in
    "(" ++ maybeField ++ "field " ++ toJsonString a ++ " " ++ fromTypeAnnotation prefix b ++ ")"


decoderName : String -> String
decoderName a =
    firstToLowerCase a ++ "Decoder"


firstToLowerCase : String -> String
firstToLowerCase a =
    case String.toList a of
        first :: rest ->
            Char.toLower first :: rest |> String.fromList

        _ ->
            a
