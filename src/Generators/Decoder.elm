module Generators.Decoder exposing (fromFile)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import String exposing (join)
import Utils.Imports as Imports
import Utils.Utils exposing (fileToModuleName, firstToLowerCase, letterByInt, toJsonString, wrapInParentheses)


{-| To get Elm module for decoding types in file.
-}
fromFile : File -> String
fromFile a =
    [ "module Generated." ++ fileToModuleName a ++ ".Decode exposing (..)"
    , ""
    , "import " ++ fileToModuleName a ++ " as A"
    , "import Generated.Basics.Decode as BD"
    , "import Json.Decode as D exposing (Decoder)"
    , a.imports |> Imports.fromList "Decode"
    , ""
    , a.declarations |> List.filterMap fromDeclaration |> join "\n\n"
    , ""
    ]
        |> join "\n"


{-| To maybe get decoder from declaration.
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


{-| To get decoder from type alias.
-}
fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    a |> fromType ("\n  " ++ fromTypeAnnotation a.typeAnnotation)


{-| To get decoder from custom type.
-}
fromCustomType : Type -> String
fromCustomType a =
    let
        cases : String
        cases =
            a.constructors
                |> List.map (\v -> Tuple.pair (v |> Node.value |> .name |> Node.value) v)
                |> List.map fromCustomTypeConstructor
                |> join "\n    "

        fail : String
        fail =
            "\n    _ -> D.fail (\"I can't decode \" ++ " ++ toJsonString (Node.value a.name) ++ " ++ \", unknown tag \\\"\" ++ tag ++ \"\\\".\")"
    in
    a |> fromType ("\n  D.field \"type\" D.string |> D.andThen (\\tag -> case tag of\n    " ++ cases ++ fail ++ "\n  )")


{-| To get decoder from custom type constructor.
-}
fromCustomTypeConstructor : ( String, Node ValueConstructor ) -> String
fromCustomTypeConstructor ( tag, Node _ a ) =
    let
        name : String
        name =
            Node.value a.name

        arguments : String
        arguments =
            a.arguments
                |> List.indexedMap
                    (\i v ->
                        fromRecordField (Node emptyRange ( Node emptyRange (letterByInt i), v ))
                    )
                |> join " "

        decoder : String
        decoder =
            case a.arguments of
                [] ->
                    "D.succeed A." ++ name

                _ ->
                    mapFn (List.length a.arguments) ++ " A." ++ name ++ " " ++ arguments
    in
    toJsonString tag ++ " -> " ++ decoder


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
                    " D.lazy (\\_ ->" ++ b ++ "\n  )"

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
            "D.succeed ()"

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
                "Bool" ->
                    "D.bool"

                "Int" ->
                    "D.int"

                "Float" ->
                    "D.float"

                "String" ->
                    "D.string"

                "Maybe" ->
                    "D.nullable"

                "List" ->
                    "D.list"

                "Array" ->
                    "D.array"

                "Char" ->
                    "BD.char"

                "Result" ->
                    "BD.result"

                "Set" ->
                    "BD.set"

                "Dict" ->
                    "BD.dict"

                "Encode.Value" ->
                    "D.value"

                "Decode.Value" ->
                    "D.value"

                _ ->
                    (if moduleName |> List.isEmpty then
                        ""

                     else
                        (moduleName |> join "_") ++ "."
                    )
                        ++ decoderName name

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
    "(D.index " ++ String.fromInt i ++ " " ++ fromTypeAnnotation a ++ ")"


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
                    "BD.maybeField"

                _ ->
                    "D.field"

        fieldName : String
        fieldName =
            case ( a, Node.value b ) of
                ( "id", Typed (Node _ ( _, "Id" )) _ ) ->
                    "_id"

                _ ->
                    a
    in
    "(" ++ decoder ++ " " ++ toJsonString fieldName ++ " " ++ fromTypeAnnotation b ++ ")"



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
    if a == 1 then
        "D.map"

    else if a <= 8 then
        "D.map" ++ String.fromInt a

    else
        "BD.map" ++ String.fromInt a
