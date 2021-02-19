module Generators.Encode exposing (fromFile)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Documentation exposing (Documentation)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import Generators.Imports as Imports
import Utils.Utils exposing (dropLast, fileToModuleName, firstToUpper, isIdType, letterByInt, toFunctionName, toJsonString, wrapInParentheses)


fromFile : File -> String
fromFile a =
    [ "module " ++ (a |> fileToModuleName |> dropLast |> String.join ".") ++ ".Encode exposing (..)"
    , ""
    , "{-| Generated by elm-json-interop."
    , "-}"
    , ""
    , "import " ++ (a |> fileToModuleName |> String.join ".") ++ " as A"
    , "import Utils.Json.Encode_ as E_"
    , "import Json.Encode as E"
    , a.imports |> Imports.fromList "Encode"
    , ""
    , a.declarations |> List.filterMap fromDeclaration |> String.join "\n\n"
    , ""
    ]
        |> String.join "\n"


fromDeclaration : Node Declaration -> Maybe String
fromDeclaration a =
    case a |> Node.value of
        AliasDeclaration b ->
            Just (fromTypeAlias b)

        CustomTypeDeclaration b ->
            Just (fromCustomType b)

        _ ->
            Nothing


fromTypeAlias : TypeAlias -> String
fromTypeAlias a =
    fromType a ++ " " ++ fromTypeAnnotation (letterByInt 0) a.typeAnnotation


fromCustomType : Type -> String
fromCustomType a =
    let
        cases : String
        cases =
            a.constructors |> List.indexedMap fromCustomTypeConstructor |> String.join "\n    "
    in
    fromType a ++ "\n  case a of\n    " ++ cases


fromCustomTypeConstructor : Int -> Node ValueConstructor -> String
fromCustomTypeConstructor i (Node _ a) =
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
                    " " ++ (a.arguments |> List.indexedMap (\i_ _ -> letterByInt (i_ + 1)) |> String.join " ")

        encoder : String
        encoder =
            ("( \"_\", E.int " ++ String.fromInt i ++ " )") :: (a.arguments |> List.indexedMap argToEncoder) |> String.join ", "

        argToEncoder : Int -> Node TypeAnnotation -> String
        argToEncoder i_ b =
            let
                fieldName : String
                fieldName =
                    if isIdType b then
                        "_id"

                    else
                        letterByInt i_
            in
            "( " ++ toJsonString fieldName ++ ", " ++ fromTypeAnnotation (letterByInt (i_ + 1)) b ++ " )"
    in
    "A." ++ name ++ arguments ++ " -> E.object [ " ++ encoder ++ " ]"


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
                    toFunctionName name ++ " : A." ++ name ++ " -> E.Value\n"

                _ ->
                    ""

        declaration : String
        declaration =
            toFunctionName name ++ generics ++ " a ="

        generics : String
        generics =
            case a.generics of
                [] ->
                    ""

                _ ->
                    " " ++ (a.generics |> List.map (\v -> "encode" ++ firstToUpper (Node.value v)) |> String.join " ")
    in
    signature ++ declaration


fromTypeAnnotation : String -> Node TypeAnnotation -> String
fromTypeAnnotation parameter a =
    (case a |> Node.value of
        GenericType b ->
            "encode" ++ firstToUpper b ++ parameterToString parameter

        Typed b c ->
            fromTyped parameter b c

        Unit ->
            "E_.unit" ++ parameterToString parameter

        Tupled b ->
            fromTuple parameter b

        Record b ->
            fromRecord parameter b

        GenericRecord _ _ ->
            -- https://www.reddit.com/r/elm/comments/atitkl/using_extensible_record_with_json_decoder/
            "Debug.todo \"I don't know how to encode extensible record.\""

        FunctionTypeAnnotation _ _ ->
            "Debug.todo \"I don't know how to encode function.\""
    )
        |> wrapInParentheses


fromTyped : String -> Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> String
fromTyped parameter (Node _ ( moduleName, name )) a =
    let
        fn : String
        fn =
            case moduleName ++ [ name ] |> String.join "." of
                "Bool" ->
                    "E.bool"

                "Int" ->
                    "E.int"

                "Float" ->
                    "E.float"

                "String" ->
                    "E.string"

                "Maybe" ->
                    "E_.maybe"

                "List" ->
                    "E.list"

                "Array" ->
                    "E.array"

                "Char" ->
                    "E_.char"

                "Result" ->
                    "E_.result"

                "Set" ->
                    "E.set"

                "Dict" ->
                    "E_.dict"

                "Encode.Value" ->
                    "identity"

                "Decode.Value" ->
                    "identity"

                _ ->
                    (if moduleName |> List.isEmpty then
                        ""

                     else
                        (moduleName |> String.join "_") ++ "."
                    )
                        ++ toFunctionName name
    in
    call fn parameter a


fromTuple : String -> List (Node TypeAnnotation) -> String
fromTuple parameter a =
    let
        fn : String
        fn =
            if a |> List.length |> (==) 2 then
                "E_.tuple"

            else
                "E_.tuple3"
    in
    call fn parameter a


fromRecord : String -> RecordDefinition -> String
fromRecord parameter a =
    "E.object [ " ++ (a |> List.map (fromRecordField parameter) |> String.join ", ") ++ " ]"


fromRecordField : String -> Node RecordField -> String
fromRecordField parameter (Node _ ( Node _ a, b )) =
    let
        fieldName : String
        fieldName =
            if a == "id" && isIdType b then
                "_id"

            else
                a
    in
    "( " ++ toJsonString fieldName ++ ", " ++ fromTypeAnnotation (parameter ++ "." ++ a) b ++ " )"



--


call : String -> String -> List (Node TypeAnnotation) -> String
call fn parameter a =
    let
        encoders : String
        encoders =
            a
                |> List.map (fromTypeAnnotation nextParameter)
                |> List.map (\v -> "(\\" ++ nextParameter ++ " -> " ++ v ++ " )")
                |> String.join " "

        nextParameter : String
        nextParameter =
            (parameter |> String.replace "." "_") ++ "_"
    in
    fn ++ encoders ++ parameterToString parameter


parameterToString : String -> String
parameterToString a =
    " " ++ (a |> wrapInParentheses)
