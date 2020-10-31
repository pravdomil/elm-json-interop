module Generators.Encode exposing (fileToElmEncodeModule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import String exposing (join)
import Utils exposing (Argument, argumentToString, encodeJsonString, fileToModuleName, letterByInt, moduleImports, moduleNameToString, normalizeRecordFieldName, wrapInParentheses)


{-| To get Elm module for encoding types in file.
-}
fileToElmEncodeModule : File -> String
fileToElmEncodeModule a =
    [ "module Generated." ++ fileToModuleName a ++ "Encode exposing (..)"
    , ""
    , "import " ++ fileToModuleName a ++ " as A"
    , "import Generated.Basics.BasicsEncode exposing (..)"
    , "import Json.Encode exposing (..)"
    , a.imports
        |> moduleImports
            (\v vv ->
                "import Generated." ++ moduleNameToString v ++ "Encode exposing (" ++ (vv |> List.map encoderName |> join ", ") ++ ")"
            )
        |> join "\n"
    , ""
    , a.declarations |> List.filterMap declarationToEncoder |> join "\n\n"
    , ""
    ]
        |> join "\n"


{-| To maybe get encoder from declaration.
-}
declarationToEncoder : Node Declaration -> Maybe String
declarationToEncoder a =
    case a |> Node.value of
        AliasDeclaration b ->
            Just <| typeAliasToEncoder b

        CustomTypeDeclaration b ->
            Just <| customTypeToEncoder b

        _ ->
            Nothing


{-| To get encoder from type alias.
-}
typeAliasToEncoder : TypeAlias -> String
typeAliasToEncoder a =
    typeToEncoder a ++ " " ++ typeAnnotationToEncoder (Argument "" 0 "" False) a.typeAnnotation


{-| To get encoder from custom type.
-}
customTypeToEncoder : Type -> String
customTypeToEncoder a =
    let
        cases : String
        cases =
            a.constructors |> List.map customTypeConstructorToEncoder |> join "\n    "
    in
    typeToEncoder a ++ "\n  case a of\n    " ++ cases


{-| To get encoder from custom type constructor.
-}
customTypeConstructorToEncoder : Node ValueConstructor -> String
customTypeConstructorToEncoder (Node _ a) =
    let
        name : String
        name =
            Node.value a.name

        arguments : String
        arguments =
            case a.arguments of
                [] ->
                    ""

                _ ->
                    " " ++ (a.arguments |> List.indexedMap (\i _ -> letterByInt (i + 1)) |> join " ")

        encoder : String
        encoder =
            ("string " ++ encodeJsonString name) :: (a.arguments |> List.indexedMap argToEncoder) |> join ", "

        argToEncoder : Int -> Node TypeAnnotation -> String
        argToEncoder i b =
            b |> typeAnnotationToEncoder (Argument "" (1 + i) "" False)
    in
    "A." ++ name ++ arguments ++ " -> list identity [ " ++ encoder ++ " ]"


{-| To get encoder from type.
-}
typeToEncoder : { a | documentation : Maybe (Node Documentation), name : Node String, generics : List (Node String) } -> String
typeToEncoder a =
    let
        name : String
        name =
            Node.value a.name

        signature : String
        signature =
            case a.generics of
                [] ->
                    encoderName name ++ " : A." ++ name ++ " -> Value\n"

                _ ->
                    ""

        declaration : String
        declaration =
            encoderName name ++ generics ++ " a ="

        generics : String
        generics =
            case a.generics of
                [] ->
                    ""

                _ ->
                    " " ++ (a.generics |> List.map (\v -> "t_" ++ Node.value v) |> join " ")
    in
    signature ++ declaration


{-| To get encoder from type annotation.
-}
typeAnnotationToEncoder : Argument -> Node TypeAnnotation -> String
typeAnnotationToEncoder argument a =
    (case a |> Node.value of
        GenericType b ->
            "t_" ++ b ++ argumentToString argument

        Typed b c ->
            typedToEncoder argument b c

        Unit ->
            "(\\_ -> list identity [])" ++ argumentToString argument

        Tupled b ->
            tupleToEncoder argument b

        Record b ->
            fromRecord argument b

        GenericRecord _ (Node _ b) ->
            fromRecord argument b

        FunctionTypeAnnotation _ _ ->
            "Debug.todo \"I don't know how to encode function.\""
    )
        |> wrapInParentheses


{-| To get encoder from typed.
-}
typedToEncoder : Argument -> Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
typedToEncoder argument (Node _ ( moduleName, name )) arguments =
    let
        fn : String
        fn =
            case moduleName ++ [ name ] |> join "." of
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
                    "array"

                "Set" ->
                    "set"

                "Encode.Value" ->
                    "identity"

                "Decode.Value" ->
                    "identity"

                _ ->
                    moduleName ++ [ encoderName name ] |> join "."

        arguments_ : String
        arguments_ =
            case arguments of
                [] ->
                    ""

                _ ->
                    " " ++ (arguments |> List.map (typeAnnotationToEncoder { argument | disabled = True }) |> join " ")
    in
    fn ++ arguments_ ++ argumentToString argument


{-| To get encoder for tuple.
-}
tupleToEncoder : Argument -> List (Node TypeAnnotation) -> String
tupleToEncoder argument a =
    let
        parameters : String
        parameters =
            a |> List.indexedMap (\i _ -> tupleArgument i |> argumentToString) |> join ", "

        map : Int -> Node TypeAnnotation -> String
        map i b =
            typeAnnotationToEncoder (tupleArgument i) b

        tupleArgument : Int -> Argument
        tupleArgument i =
            Argument ("t" ++ argument.prefix) (i + argument.letter + 1) "" False
    in
    "(\\( " ++ parameters ++ " ) -> list identity [ " ++ (a |> List.indexedMap map |> join ", ") ++ " ])" ++ argumentToString argument


fromRecord : Argument -> RecordDefinition -> String
fromRecord argument a =
    "object [ " ++ (join ", " <| List.map (fromRecordField argument) a) ++ " ]"


fromRecordField : Argument -> Node RecordField -> String
fromRecordField argument (Node _ ( Node _ a, b )) =
    "( " ++ encodeJsonString (normalizeRecordFieldName a) ++ ", " ++ typeAnnotationToEncoder { argument | suffix = "." ++ a } b ++ " )"



--


{-| To get encoder name.
-}
encoderName : String -> String
encoderName a =
    "encode" ++ a
