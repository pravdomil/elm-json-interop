module Generators.Encode exposing (fromFileToEncoder)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import String exposing (join)
import Utils exposing (Argument, argumentToString, moduleName, stringFromAlphabet, toJsonString)


fromFileToEncoder : File -> String
fromFileToEncoder f =
    let
        definitions =
            join "\n\n" <| List.filterMap fromDeclaration f.declarations
    in
    join "\n"
        [ "module Interop." ++ moduleName f ++ "Encode exposing (..)"
        , ""
        , "import " ++ moduleName f ++ " exposing (..)"
        , "import Json.Encode exposing (..)"
        , ""
        , "encodeMaybe a b = case b of\n   Just c -> a c\n   Nothing -> null"
        , ""
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
            case a.generics of
                [] ->
                    "encode" ++ name ++ " : " ++ name ++ " -> Value\n"

                _ ->
                    ""

        generics =
            case a.generics of
                [] ->
                    ""

                _ ->
                    (++) " " <| join " " <| List.map (\(Node _ v) -> "t_" ++ v) a.generics

        declaration =
            "encode" ++ name ++ generics ++ " a ="
    in
    signature ++ declaration


fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ " " ++ fromTypeAnnotation (Argument "" 0 "" False) a.typeAnnotation


fromCustomType : Type -> String
fromCustomType a =
    let
        cases =
            join "\n    " <| List.map fromCustomTypeConstructor a.constructors
    in
    fromType a ++ "\n  case a of\n    " ++ cases


fromCustomTypeConstructor : Node ValueConstructor -> String
fromCustomTypeConstructor (Node _ a) =
    let
        name =
            Node.value a.name

        params =
            case a.arguments of
                [] ->
                    ""

                _ ->
                    " " ++ (join " " <| List.indexedMap (\b _ -> stringFromAlphabet (b + 1)) a.arguments)

        map i b =
            fromTypeAnnotation (Argument "" (1 + i) "" False) b

        encoder : String
        encoder =
            case a.arguments of
                [] ->
                    "list identity []"

                b :: [] ->
                    map 0 b

                _ ->
                    "list identity [ " ++ (join ", " <| List.indexedMap map a.arguments) ++ " ]"
    in
    name ++ params ++ " -> object [ ( " ++ toJsonString name ++ ", " ++ encoder ++ " ) ]"


fromTypeAnnotation : Argument -> Node TypeAnnotation -> String
fromTypeAnnotation argument (Node _ a) =
    case a of
        GenericType b ->
            "t_" ++ b ++ argumentToString argument

        Typed b c ->
            fromTyped argument b c

        Unit ->
            "(\\_ -> list identity [])" ++ argumentToString argument

        Tupled b ->
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
            case nodes of
                [] ->
                    ""

                _ ->
                    (++) " " <| join " " <| List.map (fromTypeAnnotation { argument | disabled = True }) nodes

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

                "Set" ->
                    "set"

                "Encode.Value" ->
                    "identity"

                _ ->
                    name ++ [ "encode" ++ str ] |> join "."
    in
    fn ++ generics ++ argumentToString argument


fromTuple : Argument -> List (Node TypeAnnotation) -> String
fromTuple argument a =
    let
        arguments =
            join ", " <| List.indexedMap (\i _ -> stringFromAlphabet (i + argument.char + 1)) a

        map i b =
            fromTypeAnnotation (Argument "" (i + argument.char + 1) "" False) b
    in
    "(\\( " ++ arguments ++ " ) -> list identity [ " ++ (join ", " <| List.indexedMap map a) ++ " ])" ++ argumentToString argument


fromRecord : Argument -> RecordDefinition -> String
fromRecord argument a =
    "object [ " ++ (join ", " <| List.map (fromRecordField argument) a) ++ " ]"


fromRecordField : Argument -> Node RecordField -> String
fromRecordField argument (Node _ ( Node _ a, b )) =
    "( " ++ toJsonString a ++ ", " ++ fromTypeAnnotation { argument | suffix = "." ++ a } b ++ " )"
