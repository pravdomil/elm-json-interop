module Generators.Encode exposing (fromFile)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module exposing (Module(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern exposing (Pattern(..), QualifiedNameRef)
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
                { moduleName = n (name ++ [ "Encode" ])
                , exposingList = n (All Range.emptyRange)
                }
                |> n

        imports : List (Node Import)
        imports =
            declarations
                |> List.concatMap Dependencies.fromDeclaration
                |> List.filterMap
                    (\( v, _ ) ->
                        if v == [] || v == [ "A" ] || v == [ "E" ] || v == [ "E_" ] then
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
    , Import (n [ "Json", "Encode" ]) (Just (n [ "E" ])) Nothing
    , Import (n [ "Utils", "Json", "Encode_" ]) (Just (n [ "E_" ])) (Just (n (Explicit [ n (TypeOrAliasExpose "Encoder") ])))
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
    let
        arg : Argument
        arg =
            Argument 0
    in
    FunctionDeclaration
        { documentation = Nothing
        , signature = a |> signature |> Just
        , declaration =
            { name = a.name |> Node.map Function.nameFromString
            , arguments = a.generics |> List.map (Node.map VarPattern)
            , expression = a.typeAnnotation |> fromTypeAnnotation arg
            }
                |> n
        }
        |> n


fromCustomType : Type -> Node Declaration
fromCustomType a =
    let
        arg : Argument
        arg =
            Argument 0

        expression : Node Expression
        expression =
            case ElmSyntax.oneConstructorAndOneArgument a of
                Just ( b, c ) ->
                    LambdaExpression
                        { args =
                            [ ParenthesizedPattern
                                (n
                                    (NamedPattern (QualifiedNameRef [ "A" ] (Node.value b))
                                        [ n (Argument.toPattern arg)
                                        ]
                                    )
                                )
                                |> n
                            ]
                        , expression =
                            ElmSyntax.application
                                [ fromTypeAnnotation (Argument.next arg) c
                                , n (Argument.toExpression arg)
                                ]
                                |> n
                        }
                        |> n

                Nothing ->
                    LambdaExpression
                        { args = [ n (Argument.toPattern arg) ]
                        , expression =
                            CaseExpression
                                { expression = n (Argument.toExpression arg)
                                , cases = a.constructors |> List.indexedMap (fromCustomTypeConstructor arg)
                                }
                                |> n
                        }
                        |> n
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


fromCustomTypeConstructor : Argument -> Int -> Node ValueConstructor -> ( Node Pattern, Node Expression )
fromCustomTypeConstructor arg i (Node _ a) =
    let
        ( args, nextArg ) =
            let
                fold : a -> ( List Argument, Argument ) -> ( List Argument, Argument )
                fold _ ( acc, arg_ ) =
                    ( arg_ :: acc
                    , Argument.next arg_
                    )
            in
            a.arguments
                |> List.foldl fold ( [], Argument.next arg )
                |> Tuple.mapFirst List.reverse

        expressions : List (Node Expression)
        expressions =
            let
                fold : Node TypeAnnotation -> ( Int, Argument, List (Node Expression) ) -> ( Int, Argument, List (Node Expression) )
                fold b ( i_, arg_, acc ) =
                    let
                        expression : Node Expression
                        expression =
                            TupledExpression
                                [ n (Literal (String_.letterFromAlphabet i_))
                                , ElmSyntax.application
                                    [ fromTypeAnnotation nextArg b
                                    , n (Argument.toExpression arg_)
                                    ]
                                    |> n
                                ]
                                |> n
                    in
                    ( i_ + 1
                    , Argument.next arg_
                    , expression :: acc
                    )
            in
            a.arguments
                |> List.foldl fold ( 0, Argument.next arg, [] )
                |> (\( _, _, v ) -> v)
                |> List.reverse
                |> (::)
                    (TupledExpression
                        [ n (Literal "_")
                        , n
                            (ElmSyntax.application
                                [ n (FunctionOrValue [ "E" ] "int")
                                , n (Integer i)
                                ]
                            )
                        ]
                        |> n
                    )
    in
    ( NamedPattern
        (QualifiedNameRef [ "A" ] (Node.value a.name))
        (args |> List.map (Argument.toPattern >> n))
        |> n
    , ElmSyntax.application
        [ n (FunctionOrValue [ "E" ] "object")
        , n (ListExpr expressions)
        ]
        |> n
    )


fromTypeAnnotation : Argument -> Node TypeAnnotation -> Node Expression
fromTypeAnnotation arg a =
    Node.map
        (\v ->
            case v of
                GenericType b ->
                    FunctionOrValue [] b

                Typed b c ->
                    fromTyped arg b c

                Unit ->
                    FunctionOrValue [ "E_" ] "unit"

                Tupled b ->
                    fromTuple arg b

                Record b ->
                    fromRecord arg b

                GenericRecord _ _ ->
                    -- https://www.reddit.com/r/elm/comments/atitkl/using_extensible_record_with_json_decoder/
                    ElmSyntax.application
                        [ n (FunctionOrValue [ "Debug" ] "todo")
                        , n (Literal "I don't know how to encode extensible record.")
                        ]

                FunctionTypeAnnotation _ _ ->
                    ElmSyntax.application
                        [ n (FunctionOrValue [ "Debug" ] "todo")
                        , n (Literal "I don't know how to encode function.")
                        ]
        )
        a


fromTuple : Argument -> List (Node TypeAnnotation) -> Expression
fromTuple arg a =
    let
        expression : Node Expression
        expression =
            FunctionOrValue [ "E_" ]
                (if List.length a == 2 then
                    "tuple"

                 else
                    "tuple3"
                )
                |> n
    in
    ElmSyntax.application (expression :: List.map (fromTypeAnnotation arg) a)


fromTyped : Argument -> Node ( ModuleName, String ) -> List (Node TypeAnnotation) -> Expression
fromTyped arg b a =
    let
        toExpression : ( ModuleName, String ) -> Expression
        toExpression ( module_, name ) =
            case ( module_, name ) of
                ( [], "Bool" ) ->
                    FunctionOrValue [ "E" ] "bool"

                ( [], "Int" ) ->
                    FunctionOrValue [ "E" ] "int"

                ( [], "Float" ) ->
                    FunctionOrValue [ "E" ] "float"

                ( [], "Char" ) ->
                    FunctionOrValue [ "E_" ] "char"

                ( [], "String" ) ->
                    FunctionOrValue [ "E" ] "string"

                ( [], "List" ) ->
                    FunctionOrValue [ "E" ] "list"

                ( [ "Array" ], "Array" ) ->
                    FunctionOrValue [ "E" ] "array"

                ( [], "Maybe" ) ->
                    FunctionOrValue [ "E_" ] "maybe"

                ( [], "Result" ) ->
                    FunctionOrValue [ "E_" ] "result"

                ( [ "Set" ], "Set" ) ->
                    FunctionOrValue [ "E" ] "set"

                ( [ "Dict" ], "Dict" ) ->
                    FunctionOrValue [ "E_" ] "dict"

                ( [ "Json", "Encode" ], "Value" ) ->
                    FunctionOrValue [] "identity"

                ( [ "Json", "Decode" ], "Value" ) ->
                    FunctionOrValue [] "identity"

                _ ->
                    FunctionOrValue
                        (if module_ == [] then
                            []

                         else
                            module_ ++ [ "Encode" ]
                        )
                        (Function.nameFromString name)
    in
    ElmSyntax.application (Node.map toExpression b :: List.map (fromTypeAnnotation arg) a)


fromRecord : Argument -> RecordDefinition -> Expression
fromRecord arg a =
    LambdaExpression
        { args = [ n (Argument.toPattern arg) ]
        , expression =
            ElmSyntax.application
                [ n (FunctionOrValue [ "E" ] "object")
                , n (ListExpr (a |> List.map (fromRecordField arg)))
                ]
                |> n
        }


fromRecordField : Argument -> Node RecordField -> Node Expression
fromRecordField arg a =
    Node.map
        (\( name, b ) ->
            let
                name_ : Node String
                name_ =
                    Node.map
                        (\v ->
                            if v == "id" then
                                "_id"

                            else
                                v
                        )
                        name
            in
            TupledExpression
                [ Node.map Literal name_
                , ElmSyntax.application
                    [ fromTypeAnnotation (Argument.next arg) b
                    , n (RecordAccess (n (Argument.toExpression arg)) name_)
                    ]
                    |> n
                ]
        )
        a



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
                                typed ( [], "Encoder" ) [ Node.map GenericType v ]
                            )
                   )
                ++ [ typed
                        ( [], "Encoder" )
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
