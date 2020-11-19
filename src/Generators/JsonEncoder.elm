module Generators.JsonEncoder exposing (fromFile)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import String exposing (join, replace)
import Utils.Utils exposing (denormalizeRecordFieldName, encodeJsonString, fileToModuleName, firstToLowerCase, letterByInt, moduleImports, moduleNameToString, wrapInParentheses)


{-| To get Elm module for encoding types in file.
-}
fromFile : File -> String
fromFile a =
    [ "module Generated." ++ fileToModuleName a ++ ".Encode exposing (..)"
    , ""
    , "import " ++ fileToModuleName a ++ " as A"
    , "import Generated.Basics.Encode as BE"
    , "import Json.Encode as E"
    , a.imports
        |> moduleImports
            (\v vv ->
                "import Generated." ++ moduleNameToString v ++ ".Encode exposing (" ++ (vv |> List.map encoderName |> join ", ") ++ ")"
            )
        |> join "\n"
    , ""
    , a.declarations |> List.filterMap fromDeclaration |> join "\n\n"
    , ""
    ]
        |> join "\n"


{-| To maybe get encoder from declaration.
-}
fromDeclaration : Node Declaration -> Maybe String
fromDeclaration a =
    case a |> Node.value of
        AliasDeclaration b ->
            Just (fromTypeAlias b)

        CustomTypeDeclaration b ->
            Just (fromCustomType b)

        _ ->
            Nothing


{-| To get encoder from type alias.
-}
fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ " " ++ fromTypeAnnotation (letterByInt 0) a.typeAnnotation


{-| To get encoder from custom type.
-}
fromCustomType : Type -> String
fromCustomType a =
    let
        cases : String
        cases =
            a.constructors |> List.map fromCustomTypeConstructor |> join "\n    "
    in
    fromType a ++ "\n  case a of\n    " ++ cases


{-| To get encoder from custom type constructor.
-}
fromCustomTypeConstructor : Node ValueConstructor -> String
fromCustomTypeConstructor (Node _ a) =
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
            ("E.string " ++ encodeJsonString name) :: (a.arguments |> List.indexedMap argToEncoder) |> join ", "

        argToEncoder : Int -> Node TypeAnnotation -> String
        argToEncoder i b =
            b |> fromTypeAnnotation (letterByInt (1 + i))
    in
    "A." ++ name ++ arguments ++ " -> E.list identity [ " ++ encoder ++ " ]"


{-| To get encoder from type.
-}
fromType : { a | documentation : Maybe (Node Documentation), name : Node String, generics : List (Node String) } -> String
fromType a =
    let
        name : String
        name =
            Node.value a.name

        signature : String
        signature =
            case a.generics of
                [] ->
                    encoderName name ++ " : A." ++ name ++ " -> E.Value\n"

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
fromTypeAnnotation : String -> Node TypeAnnotation -> String
fromTypeAnnotation parameter a =
    (case a |> Node.value of
        GenericType b ->
            "t_" ++ b ++ parameterToString parameter

        Typed b c ->
            fromTyped parameter b c

        Unit ->
            "(\\_ -> E.list identity [])" ++ parameterToString parameter

        Tupled b ->
            fromTuple parameter b

        Record b ->
            fromRecord parameter b

        GenericRecord _ (Node _ b) ->
            fromRecord parameter b

        FunctionTypeAnnotation _ _ ->
            "Debug.todo \"I don't know how to encode function.\""
    )
        |> wrapInParentheses


{-| To get encoder from typed.
-}
fromTyped : String -> Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
fromTyped parameter (Node _ ( moduleName, name )) arguments =
    let
        fn : String
        fn =
            case moduleName ++ [ name ] |> join "." of
                "Bool" ->
                    "E.bool"

                "Int" ->
                    "E.int"

                "Float" ->
                    "E.float"

                "String" ->
                    "E.string"

                "Maybe" ->
                    "BE.maybe"

                "List" ->
                    "E.list"

                "Array" ->
                    "E.array"

                "Char" ->
                    "BE.char"

                "Result" ->
                    "BE.result"

                "Set" ->
                    "E.set"

                "Dict" ->
                    "BE.dict"

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
                    let
                        nextParameter : String
                        nextParameter =
                            (parameter |> replace "." "_") ++ "_"
                    in
                    arguments
                        |> List.map (fromTypeAnnotation nextParameter)
                        |> List.map
                            (\v ->
                                "(\\" ++ nextParameter ++ " -> " ++ v ++ " )"
                            )
                        |> join " "
    in
    fn ++ arguments_ ++ parameterToString parameter


{-| To get encoder for tuple.
-}
fromTuple : String -> List (Node TypeAnnotation) -> String
fromTuple parameter a =
    let
        parameters : String
        parameters =
            a |> List.indexedMap (\i _ -> parameterFromInt i) |> join ", "

        toEncoder : Int -> Node TypeAnnotation -> String
        toEncoder i b =
            b |> fromTypeAnnotation (parameterFromInt i)

        parameterFromInt : Int -> String
        parameterFromInt i =
            parameter ++ "_" ++ letterByInt i
    in
    "(\\( " ++ parameters ++ " ) -> E.list identity [ " ++ (a |> List.indexedMap toEncoder |> join ", ") ++ " ])" ++ parameterToString parameter


{-| To get encoder from record.
-}
fromRecord : String -> RecordDefinition -> String
fromRecord parameter a =
    "E.object [ " ++ (a |> List.map (fromRecordField parameter) |> join ", ") ++ " ]"


{-| To get encoder from record field.
-}
fromRecordField : String -> Node RecordField -> String
fromRecordField parameter (Node _ ( Node _ a, b )) =
    "( " ++ encodeJsonString (denormalizeRecordFieldName a) ++ ", " ++ fromTypeAnnotation (parameter ++ "." ++ a) b ++ " )"



--


{-| To get encoder name.
-}
encoderName : String -> String
encoderName a =
    firstToLowerCase a


{-| To convert parameter to string.
-}
parameterToString : String -> String
parameterToString a =
    " " ++ (a |> wrapInParentheses)
