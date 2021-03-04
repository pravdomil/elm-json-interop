module Generators.Decode exposing (fromFile)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.Expression exposing (Expression(..), FunctionImplementation, Lambda, RecordSetter)
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Infix exposing (InfixDirection(..))
import Elm.Syntax.Module as Module exposing (Module(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..))
import Elm.Syntax.Range as Range
import Elm.Syntax.Signature exposing (Signature)
import Elm.Syntax.Type exposing (Type, ValueConstructor)
import Elm.Syntax.TypeAlias exposing (TypeAlias)
import Elm.Syntax.TypeAnnotation exposing (RecordDefinition, RecordField, TypeAnnotation(..))
import Elm.Writer as Writer
import Utils.Function as Function
import Utils.String_ as String_


fromFile : File -> String
fromFile a =
    let
        suffix : String
        suffix =
            "Decode"

        name : ModuleName
        name =
            a.moduleDefinition |> Node.value |> Module.moduleName

        module_ : Node Module
        module_ =
            NormalModule
                { moduleName = n (name ++ [ suffix ])
                , exposingList = n (All Range.emptyRange)
                }
                |> n

        imports : List (Node Import)
        imports =
            additionalImports name

        declarations : List (Node Declaration)
        declarations =
            a.declarations |> List.filterMap fromDeclaration
    in
    { a
        | moduleDefinition = module_
        , imports = imports
        , declarations = declarations
    }
        |> Writer.writeFile
        |> Writer.write
        |> String.lines
        |> (\v ->
                List.take 1 v ++ [ "{-| Generated by elm-json-interop.\n-}" ] ++ List.drop 1 v
           )
        |> String.join "\n"


additionalImports : ModuleName -> List (Node Import)
additionalImports a =
    let
        import_ : ModuleName -> String -> Import
        import_ b c =
            Import (n b) (Just (n [ c ])) Nothing

        importExposingType : ModuleName -> String -> String -> Import
        importExposingType b c d =
            Import (n b) (Just (n [ c ])) (Just (n (Explicit [ n (TypeOrAliasExpose d) ])))
    in
    [ Import (n a) Nothing (Just (n (All Range.emptyRange)))
    , importExposingType [ "Json", "Decode" ] "D" "Decoder"
    , import_ [ "Utils", "Json", "Decode_" ] "D_"
    ]
        |> List.map n


fromDeclaration : Node Declaration -> Maybe (Node Declaration)
fromDeclaration a =
    case a |> Node.value of
        FunctionDeclaration _ ->
            Nothing

        AliasDeclaration b ->
            Just (fromTypeAlias b)

        CustomTypeDeclaration b ->
            Just (fromCustomType b)

        PortDeclaration _ ->
            Nothing

        InfixDeclaration _ ->
            Nothing

        Destructuring _ _ ->
            Nothing


fromTypeAlias : TypeAlias -> Node Declaration
fromTypeAlias a =
    FunctionDeclaration
        { documentation = Nothing
        , signature = a |> signature |> Just
        , declaration =
            { name = a.name |> Node.map Function.nameFromString
            , arguments = a.generics |> List.map (Node.map VarPattern)
            , expression = a.typeAnnotation |> fromTypeAnnotation
            }
                |> n
        }
        |> n


fromCustomType : Type -> Node Declaration
fromCustomType a =
    let
        oneConstructorAndOneArgument : Maybe (Node TypeAnnotation)
        oneConstructorAndOneArgument =
            a.constructors |> listSingleton |> Maybe.andThen (Node.value >> .arguments >> listSingleton)

        expression : Node Expression
        expression =
            pipe
                (n
                    (application
                        [ n (FunctionOrValue [ "D" ] "field")
                        , n (Literal "_")
                        , n (FunctionOrValue [ "D" ] "int")
                        ]
                    )
                )
                (n decoderFn)
                |> n

        decoderFn : Expression
        decoderFn =
            application
                [ n (FunctionOrValue [ "D" ] "andThen")
                , n
                    (LambdaExpression
                        { args = [ n (VarPattern "i___") ]
                        , expression =
                            CaseExpression
                                { expression = n (FunctionOrValue [] "i___")
                                , cases = List.indexedMap fromCustomTypeConstructor a.constructors ++ [ fail ]
                                }
                                |> n
                        }
                    )
                ]

        fail : ( Node Pattern, Node Expression )
        fail =
            ( n AllPattern
            , n
                (application
                    [ n (FunctionOrValue [ "D" ] "fail")
                    , n
                        (append
                            (n (Literal ("I can't decode \\\"" ++ Node.value a.name ++ "\\\", unknown variant with index ")))
                            (n
                                (append
                                    (n
                                        (application
                                            [ n (FunctionOrValue [ "String" ] "fromInt")
                                            , n (FunctionOrValue [] "i___")
                                            ]
                                        )
                                    )
                                    (n (Literal "."))
                                )
                            )
                        )
                    ]
                )
            )
    in
    FunctionDeclaration
        { documentation = Nothing
        , signature = a |> signature |> Just
        , declaration =
            { name = a.name |> Node.map Function.nameFromString
            , arguments = a.generics |> List.map (Node.map VarPattern)
            , expression = expression
            }
                |> n
        }
        |> n


fromCustomTypeConstructor : Int -> Node ValueConstructor -> ( Node Pattern, Node Expression )
fromCustomTypeConstructor i (Node _ a) =
    let
        decoder : Expression
        decoder =
            mapApplication
                (n (FunctionOrValue [] (Node.value a.name)))
                arguments

        arguments : List (Node Expression)
        arguments =
            a.arguments
                |> List.indexedMap
                    (\i_ v ->
                        n
                            (fromRecordField
                                ( n (String_.letterFromAlphabet i_)
                                , v
                                )
                            )
                    )
    in
    ( n (IntPattern i)
    , n decoder
    )


signature : { a | generics : List (Node String), name : Node String } -> Node Signature
signature a =
    let
        arguments : List (Node TypeAnnotation)
        arguments =
            []
                ++ (a.generics
                        |> List.map
                            (\v ->
                                typed "Decoder" [ Node.map GenericType v ]
                            )
                   )
                ++ [ typed
                        "Decoder"
                        [ typed (Node.value a.name) (a.generics |> List.map (Node.map GenericType))
                        ]
                   ]

        typed : String -> List (Node TypeAnnotation) -> Node TypeAnnotation
        typed b c =
            n (Typed (n ( [], b )) c)
    in
    n (Signature (Node.map Function.nameFromString a.name) (toFunctionTypeAnnotation arguments))


fromTypeAnnotation : Node TypeAnnotation -> Node Expression
fromTypeAnnotation a =
    a
        |> Node.map
            (\v ->
                case v of
                    GenericType b ->
                        FunctionOrValue [] b

                    Typed b c ->
                        fromTyped b c

                    Unit ->
                        FunctionOrValue [ "D_" ] "unit"

                    Tupled b ->
                        fromTuple b

                    Record b ->
                        fromRecord b

                    GenericRecord _ _ ->
                        -- https://www.reddit.com/r/elm/comments/atitkl/using_extensible_record_with_json_decoder/
                        application
                            [ n (FunctionOrValue [ "Debug" ] "todo")
                            , n (Literal "I don't know how to decode extensible record.")
                            ]

                    FunctionTypeAnnotation _ _ ->
                        application
                            [ n (FunctionOrValue [ "Debug" ] "todo")
                            , n (Literal "I don't know how to decode function.")
                            ]
            )


fromTyped : Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> Expression
fromTyped b a =
    let
        toExpression : ( ModuleName, String ) -> Expression
        toExpression ( module_, name ) =
            case ( module_, name ) of
                ( [], "Bool" ) ->
                    FunctionOrValue [ "D" ] "bool"

                ( [], "Int" ) ->
                    FunctionOrValue [ "D" ] "int"

                ( [], "Float" ) ->
                    FunctionOrValue [ "D" ] "float"

                ( [], "Char" ) ->
                    FunctionOrValue [ "D_" ] "char"

                ( [], "String" ) ->
                    FunctionOrValue [ "D" ] "string"

                ( [], "List" ) ->
                    FunctionOrValue [ "D" ] "list"

                ( [], "Array" ) ->
                    FunctionOrValue [ "D" ] "array"

                ( [], "Maybe" ) ->
                    FunctionOrValue [ "D_" ] "maybe"

                ( [], "Result" ) ->
                    FunctionOrValue [ "D_" ] "result"

                ( [], "Set" ) ->
                    FunctionOrValue [ "D_" ] "set"

                ( [], "Dict" ) ->
                    FunctionOrValue [ "D_" ] "dict"

                ( [ "Encode" ], "Value" ) ->
                    FunctionOrValue [ "D" ] "value"

                ( [ "Decode" ], "Value" ) ->
                    FunctionOrValue [ "D" ] "value"

                _ ->
                    FunctionOrValue module_ (Function.nameFromString name)
    in
    application (Node.map toExpression b :: List.map fromTypeAnnotation a)


fromTuple : List (Node TypeAnnotation) -> Expression
fromTuple a =
    let
        fn : Node Expression
        fn =
            (if a |> List.length |> (==) 2 then
                FunctionOrValue [ "D_" ] "tuple"

             else
                FunctionOrValue [ "D_" ] "tuple3"
            )
                |> n
    in
    application (fn :: List.map fromTypeAnnotation a)


fromRecord : RecordDefinition -> Expression
fromRecord a =
    let
        fn : Expression
        fn =
            if a |> List.isEmpty then
                RecordExpr []

            else
                LambdaExpression
                    { args = List.indexedMap (\i _ -> n (VarPattern ("v" ++ String.fromInt (i + 1)))) a
                    , expression = n (RecordExpr (List.indexedMap toSetter a))
                    }

        toSetter : Int -> Node RecordField -> Node RecordSetter
        toSetter i b =
            b |> Node.map (Tuple.mapSecond (Node.map (always (FunctionOrValue [] ("v" ++ String.fromInt (i + 1))))))
    in
    mapApplication
        (n fn)
        (List.map (Node.map fromRecordField) a)


fromRecordField : RecordField -> Expression
fromRecordField ( a, b ) =
    let
        fn : Node Expression
        fn =
            (case Node.value b of
                Typed (Node _ ( _, "Maybe" )) _ ->
                    FunctionOrValue [ "D_" ] "maybeField"

                _ ->
                    FunctionOrValue [ "D" ] "field"
            )
                |> n

        name : Node Expression
        name =
            a
                |> Node.map
                    (\v ->
                        if v == "id" then
                            "_id"

                        else
                            v
                    )
                |> Node.map Literal
    in
    application [ fn, name, fromTypeAnnotation b ]



--


n : a -> Node a
n =
    Node Range.emptyRange


toFunctionTypeAnnotation : List (Node TypeAnnotation) -> Node TypeAnnotation
toFunctionTypeAnnotation a =
    let
        helper : List (Node TypeAnnotation) -> Node TypeAnnotation -> Node TypeAnnotation
        helper b c =
            b |> List.foldl (\v acc -> FunctionTypeAnnotation v acc |> n) c
    in
    case a |> List.reverse of
        [] ->
            n Unit

        b :: [] ->
            b

        b :: c :: rest ->
            FunctionTypeAnnotation c b |> n |> helper rest


application : List (Node Expression) -> Expression
application a =
    a |> List.map (ParenthesizedExpression >> n) |> Application


mapApplication : Node Expression -> List (Node Expression) -> Expression
mapApplication b a =
    case a of
        [] ->
            application
                [ n (FunctionOrValue [ "D" ] "succeed")
                , b
                ]

        c :: [] ->
            application
                [ n (FunctionOrValue [ "D" ] "map")
                , b
                , c
                ]

        _ ->
            application
                (n (FunctionOrValue [ "D" ] ("map" ++ String.fromInt (min 8 (List.length a))))
                    :: b
                    :: (a |> List.take 8)
                )
                |> (\v ->
                        a
                            |> List.drop 8
                            |> List.foldl
                                (\vv acc ->
                                    pipe
                                        (n acc)
                                        (n
                                            (application
                                                [ n (FunctionOrValue [ "D_" ] "apply")
                                                , vv
                                                ]
                                            )
                                        )
                                )
                                v
                   )


pipe : Node Expression -> Node Expression -> Expression
pipe a b =
    OperatorApplication "|>" Left a b


append : Node Expression -> Node Expression -> Expression
append a b =
    OperatorApplication "++" Right a b


listSingleton : List a -> Maybe a
listSingleton a =
    case a of
        b :: [] ->
            Just b

        _ ->
            Nothing
