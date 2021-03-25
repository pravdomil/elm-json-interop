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
import Utils.Argument as Argument exposing (Argument(..))
import Utils.Dependencies as Dependencies
import Utils.ElmSyntax as ElmSyntax
import Utils.Function as Function
import Utils.String_ as String_


fromFile : File -> String
fromFile a =
    let
        name : ModuleName
        name =
            a.moduleDefinition |> Node.value |> Module.moduleName

        module_ : Node Module
        module_ =
            NormalModule
                { moduleName = n (name ++ [ "Decode" ])
                , exposingList = n (All Range.emptyRange)
                }
                |> n

        imports : List (Node Import)
        imports =
            declarations
                |> List.concatMap Dependencies.fromDeclaration
                |> List.filterMap
                    (\( v, _ ) ->
                        if v == [] || v == [ "A" ] || v == [ "D" ] || v == [ "D_" ] || v == [ "String" ] then
                            Nothing

                        else
                            Just (n (Import (n v) Nothing Nothing))
                    )
                |> (++) (additionalImports name)

        declarations : List (Node Declaration)
        declarations =
            a.declarations |> List.filterMap fromDeclaration
    in
    { a
        | moduleDefinition = module_
        , imports = imports
        , declarations = declarations
    }
        |> ElmSyntax.writeFile


additionalImports : ModuleName -> List (Node Import)
additionalImports a =
    [ Import (n a) (Just (n [ "A" ])) Nothing
    , Import (n [ "Json", "Decode" ]) (Just (n [ "D" ])) (Just (n (Explicit [ n (TypeOrAliasExpose "Decoder") ])))
    , Import (n [ "Utils", "Json", "Decode_" ]) (Just (n [ "D_" ])) Nothing
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
        expression : Node Expression
        expression =
            case ElmSyntax.oneConstructorAndOneArgument a of
                Just ( b, c ) ->
                    mapApplication
                        (Node.map (FunctionOrValue [ "A" ]) b)
                        [ fromTypeAnnotation c ]
                        |> n

                Nothing ->
                    pipe
                        (n
                            (ElmSyntax.application
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
            ElmSyntax.application
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
                (ElmSyntax.application
                    [ n (FunctionOrValue [ "D" ] "fail")
                    , n
                        (append
                            (n (Literal ("I can't decode \\\"" ++ Node.value a.name ++ "\\\", unknown variant with index ")))
                            (n
                                (append
                                    (n
                                        (ElmSyntax.application
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
                (n (FunctionOrValue [ "A" ] (Node.value a.name)))
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


fromTypeAnnotation : Node TypeAnnotation -> Node Expression
fromTypeAnnotation a =
    Node.map
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
                    ElmSyntax.application
                        [ n (FunctionOrValue [ "Debug" ] "todo")
                        , n (Literal "I don't know how to decode extensible record.")
                        ]

                FunctionTypeAnnotation _ _ ->
                    ElmSyntax.application
                        [ n (FunctionOrValue [ "Debug" ] "todo")
                        , n (Literal "I don't know how to decode function.")
                        ]
        )
        a


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

                ( [ "Array" ], "Array" ) ->
                    FunctionOrValue [ "D" ] "array"

                ( [], "Maybe" ) ->
                    FunctionOrValue [ "D_" ] "maybe"

                ( [], "Result" ) ->
                    FunctionOrValue [ "D_" ] "result"

                ( [ "Set" ], "Set" ) ->
                    FunctionOrValue [ "D_" ] "set"

                ( [ "Dict" ], "Dict" ) ->
                    FunctionOrValue [ "D_" ] "dict"

                ( [ "Json", "Encode" ], "Value" ) ->
                    FunctionOrValue [ "D" ] "value"

                ( [ "Json", "Decode" ], "Value" ) ->
                    FunctionOrValue [ "D" ] "value"

                _ ->
                    FunctionOrValue
                        (if module_ == [] then
                            []

                         else
                            module_ ++ [ "Decode" ]
                        )
                        (Function.nameFromString name)
    in
    ElmSyntax.application (Node.map toExpression b :: List.map fromTypeAnnotation a)


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
    ElmSyntax.application (fn :: List.map fromTypeAnnotation a)


fromRecord : RecordDefinition -> Expression
fromRecord a =
    let
        fn : Expression
        fn =
            if a |> List.isEmpty then
                RecordExpr []

            else
                LambdaExpression
                    { args = List.indexedMap (\i _ -> Argument i |> Argument.toPattern |> n) a
                    , expression = n (RecordExpr (List.indexedMap toSetter a))
                    }

        toSetter : Int -> Node RecordField -> Node RecordSetter
        toSetter i b =
            b |> Node.map (Tuple.mapSecond (Node.map (always (Argument i |> Argument.toExpression))))
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
    ElmSyntax.application [ fn, name, fromTypeAnnotation b ]



--


signature : { a | generics : List (Node String), name : Node String } -> Node Signature
signature a =
    let
        arguments : List (Node TypeAnnotation)
        arguments =
            []
                ++ (a.generics
                        |> List.map
                            (\v ->
                                typed ( [], "Decoder" ) [ Node.map GenericType v ]
                            )
                   )
                ++ [ typed
                        ( [], "Decoder" )
                        [ typed ( [ "A" ], Node.value a.name ) (a.generics |> List.map (Node.map GenericType))
                        ]
                   ]

        typed : ( List String, String ) -> List (Node TypeAnnotation) -> Node TypeAnnotation
        typed b c =
            n (Typed (n b) c)
    in
    { name = Node.map Function.nameFromString a.name
    , typeAnnotation = ElmSyntax.function arguments
    }
        |> n


n : a -> Node a
n =
    Node Range.emptyRange


mapApplication : Node Expression -> List (Node Expression) -> Expression
mapApplication b a =
    case a of
        [] ->
            ElmSyntax.application
                [ n (FunctionOrValue [ "D" ] "succeed")
                , b
                ]

        c :: [] ->
            ElmSyntax.application
                [ n (FunctionOrValue [ "D" ] "map")
                , b
                , c
                ]

        _ ->
            ElmSyntax.application
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
                                            (ElmSyntax.application
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
