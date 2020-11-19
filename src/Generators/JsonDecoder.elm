module Generators.JsonDecoder exposing (fromFile)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import String exposing (join)
import Utils.Utils exposing (denormalizeRecordFieldName, encodeJsonString, fileToModuleName, firstToLowerCase, letterByInt, maybeCustomTypeHasCustomTags, moduleImports, moduleNameToString, wrapInParentheses)


{-| To get Elm module for decoding types in file.
-}
fromFile : File -> String
fromFile a =
    [ "module Generated." ++ fileToModuleName a ++ ".Decode exposing (..)"
    , ""
    , "import " ++ fileToModuleName a ++ " as A"
    , "import Generated.Basics.Decode exposing (..)"
    , "import Json.Decode exposing (..)"
    , a.imports
        |> moduleImports
            (\v vv ->
                "import Generated." ++ moduleNameToString v ++ "Decode exposing (" ++ (vv |> List.map decoderName |> join ", ") ++ ")"
            )
        |> join "\n"
    , ""
    , a.declarations |> List.filterMap (fromDeclaration a) |> join "\n\n"
    , ""
    ]
        |> join "\n"


{-| To maybe get decoder from declaration.
-}
fromDeclaration : File -> Node Declaration -> Maybe String
fromDeclaration file a =
    case a |> Node.value of
        AliasDeclaration b ->
            Just (fromTypeAlias b)

        CustomTypeDeclaration b ->
            Just (fromCustomType file b)

        _ ->
            Nothing


{-| To get decoder from type alias.
-}
fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    a |> fromType ("\n  " ++ fromTypeAnnotation a.typeAnnotation)


{-| To get decoder from custom type.
-}
fromCustomType : File -> Type -> String
fromCustomType file a =
    let
        customTags : Maybe (List ( String, Node ValueConstructor ))
        customTags =
            a |> maybeCustomTypeHasCustomTags file

        tagDecoder : String
        tagDecoder =
            case customTags of
                Just _ ->
                    "field \"_type\" string"

                Nothing ->
                    "index 0 string"

        cases : String
        cases =
            customTags
                |> Maybe.withDefault (a.constructors |> List.map (\v -> Tuple.pair (v |> Node.value |> .name |> Node.value) v))
                |> List.map (fromCustomTypeConstructor customTags)
                |> join "\n    "

        fail : String
        fail =
            "\n    _ -> fail (\"I can't decode \" ++ " ++ encodeJsonString (Node.value a.name) ++ " ++ \", unknown tag \\\"\" ++ tag ++ \"\\\".\")"
    in
    a |> fromType ("\n  " ++ tagDecoder ++ " |> andThen (\\tag -> case tag of\n    " ++ cases ++ fail ++ "\n  )")


{-| To get decoder from custom type constructor.
-}
fromCustomTypeConstructor : Maybe a -> ( String, Node ValueConstructor ) -> String
fromCustomTypeConstructor customTags ( tag, Node _ a ) =
    let
        name : String
        name =
            Node.value a.name

        arguments : String
        arguments =
            case customTags of
                Just _ ->
                    a.arguments |> List.map fromTypeAnnotation |> join " "

                Nothing ->
                    a.arguments |> List.indexedMap (\i v -> fromElementAt (1 + i) v) |> join " "

        decoder : String
        decoder =
            case a.arguments of
                [] ->
                    "succeed A." ++ name

                _ ->
                    mapFn (List.length a.arguments) ++ " A." ++ name ++ " " ++ arguments
    in
    encodeJsonString tag ++ " -> " ++ decoder


{-| To get decoder from type.
-}
fromType : String -> { a | documentation : Maybe (Node Documentation), name : Node String, generics : List (Node String) } -> String
fromType body a =
    let
        name : String
        name =
            Node.value a.name

        lazyDecoded : Bool
        lazyDecoded =
            a.documentation
                |> Maybe.map (\v -> v |> Node.value |> String.toLower |> String.contains "lazy decode")
                |> Maybe.withDefault False

        maybeWrapInLazy : String -> String
        maybeWrapInLazy b =
            case lazyDecoded of
                True ->
                    " lazy (\\_ ->" ++ b ++ "\n  )"

                False ->
                    b

        signature : String
        signature =
            case a.generics of
                [] ->
                    decoderName name ++ " : Decoder A." ++ name ++ "\n"

                _ ->
                    ""

        declaration : String
        declaration =
            decoderName name ++ generics ++ " =" ++ maybeWrapInLazy body

        generics : String
        generics =
            case a.generics of
                [] ->
                    ""

                _ ->
                    " " ++ (a.generics |> List.map (\v -> "t_" ++ Node.value v) |> join " ")
    in
    signature ++ declaration


{-| To get decoder from type annotation.
-}
fromTypeAnnotation : Node TypeAnnotation -> String
fromTypeAnnotation a =
    (case a |> Node.value of
        GenericType b ->
            "t_" ++ b

        Typed b c ->
            fromTyped b c

        Unit ->
            "succeed ()"

        Tupled nodes ->
            fromTuple nodes

        Record b ->
            fromRecord b

        GenericRecord _ (Node _ b) ->
            fromRecord b

        FunctionTypeAnnotation _ _ ->
            "Debug.todo \"I don't know how to decode function.\""
    )
        |> wrapInParentheses


{-| To get decoder from typed.
-}
fromTyped : Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
fromTyped (Node _ ( moduleName, name )) arguments =
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

                "Maybe" ->
                    "nullable"

                "Encode.Value" ->
                    "value"

                "Decode.Value" ->
                    "value"

                _ ->
                    moduleName ++ [ decoderName name ] |> join "."

        arguments_ : String
        arguments_ =
            case arguments of
                [] ->
                    ""

                _ ->
                    " " ++ (arguments |> List.map fromTypeAnnotation |> join " ")
    in
    fn ++ arguments_


{-| To get decoder from tuple.
-}
fromTuple : List (Node TypeAnnotation) -> String
fromTuple a =
    let
        arguments : String
        arguments =
            a |> List.indexedMap fromElementAt |> join " "
    in
    mapFn (List.length a) ++ " " ++ tupleFn (List.length a) ++ " " ++ arguments


{-| To get decoder for decoding element at index.
-}
fromElementAt : Int -> Node TypeAnnotation -> String
fromElementAt i a =
    "(index " ++ String.fromInt i ++ " " ++ fromTypeAnnotation a ++ ")"


{-| To get decoder from record.
-}
fromRecord : RecordDefinition -> String
fromRecord a =
    let
        parameters : String
        parameters =
            a
                |> List.indexedMap (\i _ -> letterByInt i)
                |> join " "

        fields : String
        fields =
            a
                |> List.indexedMap (\i b -> (b |> Node.value |> Tuple.first |> Node.value) ++ " = " ++ letterByInt i)
                |> join ", "

        constructorFn : String
        constructorFn =
            "(\\" ++ parameters ++ " -> { " ++ fields ++ " })"
    in
    mapFn (List.length a) ++ " " ++ constructorFn ++ " " ++ (a |> List.map fromRecordField |> join " ")


{-| To get decoder from record field.
-}
fromRecordField : Node RecordField -> String
fromRecordField (Node _ ( Node _ a, b )) =
    let
        decoder : String
        decoder =
            case Node.value b of
                Typed (Node _ ( _, "Maybe" )) _ ->
                    "maybeField"

                _ ->
                    "field"
    in
    "(" ++ decoder ++ " " ++ encodeJsonString (denormalizeRecordFieldName a) ++ " " ++ fromTypeAnnotation b ++ ")"



--


{-| To get decoder name.
-}
decoderName : String -> String
decoderName a =
    firstToLowerCase a


{-| To get function for constructing tuples by number.
-}
tupleFn : Int -> String
tupleFn len =
    case len of
        2 ->
            "Tuple.pair"

        3 ->
            "(\\a b c -> (a, b, c))"

        _ ->
            ""


{-| To get map function name by argument count.
-}
mapFn : Int -> String
mapFn a =
    case a of
        1 ->
            "map"

        b ->
            "map" ++ String.fromInt b
