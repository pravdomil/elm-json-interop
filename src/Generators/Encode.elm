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
import Utils exposing (encodeJsonString, fileToModuleName, letterByInt, moduleImports, moduleNameToString, normalizeRecordFieldName, wrapInParentheses)


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
            Just (typeAliasToEncoder b)

        CustomTypeDeclaration b ->
            Just (customTypeToEncoder b)

        _ ->
            Nothing


{-| To get encoder from type alias.
-}
typeAliasToEncoder : TypeAlias -> String
typeAliasToEncoder a =
    typeToEncoder a ++ " " ++ typeAnnotationToEncoder (Just (letterByInt 0)) a.typeAnnotation


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
            b |> typeAnnotationToEncoder (Just (letterByInt (1 + i)))
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
typeAnnotationToEncoder : Maybe String -> Node TypeAnnotation -> String
typeAnnotationToEncoder parameter a =
    (case a |> Node.value of
        GenericType b ->
            "t_" ++ b ++ parameterToString parameter

        Typed b c ->
            typedToEncoder parameter b c

        Unit ->
            "(\\_ -> list identity [])" ++ parameterToString parameter

        Tupled b ->
            tupleToEncoder parameter b

        Record b ->
            recordToEncoder parameter b

        GenericRecord _ (Node _ b) ->
            recordToEncoder parameter b

        FunctionTypeAnnotation _ _ ->
            "Debug.todo \"I don't know how to encode function.\""
    )
        |> wrapInParentheses


{-| To get encoder from typed.
-}
typedToEncoder : Maybe String -> Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
typedToEncoder parameter (Node _ ( moduleName, name )) arguments =
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
                    " " ++ (arguments |> List.map (typeAnnotationToEncoder Nothing) |> join " ")
    in
    fn ++ arguments_ ++ parameterToString parameter


{-| To get encoder for tuple.
-}
tupleToEncoder : Maybe String -> List (Node TypeAnnotation) -> String
tupleToEncoder parameter a =
    let
        parameters : String
        parameters =
            a |> List.indexedMap (\i _ -> parameterFromInt i) |> List.filterMap identity |> join ", "

        toEncoder : Int -> Node TypeAnnotation -> String
        toEncoder i b =
            b |> typeAnnotationToEncoder (parameterFromInt i)

        parameterFromInt : Int -> Maybe String
        parameterFromInt i =
            parameter |> Maybe.map (\v -> v ++ "_" ++ letterByInt i)
    in
    "(\\( " ++ parameters ++ " ) -> list identity [ " ++ (a |> List.indexedMap toEncoder |> join ", ") ++ " ])" ++ parameterToString parameter


{-| To get encoder from record.
-}
recordToEncoder : Maybe String -> RecordDefinition -> String
recordToEncoder parameter a =
    "object [ " ++ (a |> List.map (recordFieldToEncoder parameter) |> join ", ") ++ " ]"


{-| To get encoder from record field.
-}
recordFieldToEncoder : Maybe String -> Node RecordField -> String
recordFieldToEncoder parameter (Node _ ( Node _ a, b )) =
    "( " ++ encodeJsonString (normalizeRecordFieldName a) ++ ", " ++ typeAnnotationToEncoder (parameter |> Maybe.map (\v -> v ++ "." ++ a)) b ++ " )"



--


{-| To get encoder name.
-}
encoderName : String -> String
encoderName a =
    "encode" ++ a


{-| To convert parameter to string.
-}
parameterToString : Maybe String -> String
parameterToString a =
    case a of
        Just b ->
            " " ++ (b |> wrapInParentheses)

        Nothing ->
            ""
