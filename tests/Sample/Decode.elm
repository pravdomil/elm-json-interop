module Sample.Decode exposing (..)

{-| Generated by <https://github.com/pravdomil/Elm-JSON-Interop>.
-}

import Json.Decode as D exposing (Decoder)
import Sample as A
import Sample2.Decode
import Utils.Json.Decode_ as D_


type0 : Decoder A.Type0
type0 =
    D.field "_" D.int
        |> D.andThen
            (\i___ ->
                case i___ of
                    0 ->
                        D.succeed A.Type0

                    _ ->
                        D.fail ("I can't decode \"Type0\", unknown variant with index " ++ String.fromInt i___ ++ ".")
            )


type1 : Decoder A.Type1
type1 =
    D.map A.Type1 D.string


type2 : Decoder A.Type2
type2 =
    D.field "_" D.int
        |> D.andThen
            (\i___ ->
                case i___ of
                    0 ->
                        D.map2 A.Type2 (D.field "a" D.string) (D.field "b" D.string)

                    _ ->
                        D.fail ("I can't decode \"Type2\", unknown variant with index " ++ String.fromInt i___ ++ ".")
            )


type10 : Decoder A.Type10
type10 =
    D.field "_" D.int
        |> D.andThen
            (\i___ ->
                case i___ of
                    0 ->
                        D.map8 A.Type10 (D.field "a" D.string) (D.field "b" D.string) (D.field "c" D.string) (D.field "d" D.string) (D.field "e" D.string) (D.field "f" D.string) (D.field "g" D.string) (D.field "h" D.string) |> D_.apply (D.field "i" D.string) |> D_.apply (D.field "j" D.string)

                    _ ->
                        D.fail ("I can't decode \"Type10\", unknown variant with index " ++ String.fromInt i___ ++ ".")
            )


record0 : Decoder A.Record0
record0 =
    D.succeed {}


record1 : Decoder A.Record1
record1 =
    D.map (\v1 -> { a = v1 }) (D.field "a" D.string)


record2 : Decoder A.Record2
record2 =
    D.map2
        (\v1 v2 ->
            { a = v1
            , b = v2
            }
        )
        (D.field "a" D.string)
        (D.field "b" D.string)


record10 : Decoder A.Record10
record10 =
    D.map8
        (\v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 ->
            { a = v1
            , b = v2
            , c = v3
            , d = v4
            , e = v5
            , f = v6
            , g = v7
            , h = v8
            , i = v9
            , j = v10
            }
        )
        (D.field "a" D.string)
        (D.field "b" D.string)
        (D.field "c" D.string)
        (D.field "d" D.string)
        (D.field "e" D.string)
        (D.field "f" D.string)
        (D.field "g" D.string)
        (D.field "h" D.string)
        |> D_.apply (D.field "i" D.string)
        |> D_.apply (D.field "j" D.string)


typeQualified : Decoder A.TypeQualified
typeQualified =
    Sample2.Decode.sampleType2


typeQualifiedViaAlias : Decoder A.TypeQualifiedViaAlias
typeQualifiedViaAlias =
    D.value


typeUnqualified : Decoder A.TypeUnqualified
typeUnqualified =
    D.value


sampleType : Decoder comparable -> (Decoder b -> (Decoder c -> Decoder (A.SampleType comparable b c)))
sampleType comparable b c =
    D.field "_" D.int
        |> D.andThen
            (\i___ ->
                case i___ of
                    0 ->
                        D.succeed A.Foo

                    1 ->
                        D.map A.Bar (D.field "a" (D_.tuple3 comparable b c))

                    2 ->
                        D.map3 A.Bas (D.field "a" (D.map (\v1 -> { a = v1 }) (D.field "a" comparable))) (D.field "b" (D.map (\v1 -> { b = v1 }) (D.field "b" b))) (D.field "c" (D.map (\v1 -> { c = v1 }) (D.field "c" c)))

                    _ ->
                        D.fail ("I can't decode \"SampleType\", unknown variant with index " ++ String.fromInt i___ ++ ".")
            )


sampleRecord : Decoder comparable -> (Decoder b -> (Decoder c -> Decoder (A.SampleRecord comparable b c)))
sampleRecord comparable b c =
    D.map8
        (\v1 v2 v3 v4 v5 v6 v7 v8 v9 v10 v11 v12 v13 v14 v15 ->
            { unit = v1
            , bool = v2
            , int = v3
            , float = v4
            , char = v5
            , string = v6
            , list = v7
            , array = v8
            , maybe = v9
            , result = v10
            , set = v11
            , dict = v12
            , tuple = v13
            , tuple3 = v14
            , record = v15
            }
        )
        (D.field "unit" D_.unit)
        (D.field "bool" D.bool)
        (D.field "int" D.int)
        (D.field "float" D.float)
        (D.field "char" D_.char)
        (D.field "string" D.string)
        (D.field "list" (D.list comparable))
        (D.field "array" (D.array comparable))
        |> D_.apply (D_.maybeField "maybe" (D_.maybe comparable))
        |> D_.apply (D.field "result" (D_.result comparable b))
        |> D_.apply (D.field "set" (D_.set comparable))
        |> D_.apply (D.field "dict" (D_.dict comparable b))
        |> D_.apply (D.field "tuple" (D_.tuple comparable b))
        |> D_.apply (D.field "tuple3" (D_.tuple3 comparable b c))
        |> D_.apply (D.field "record" (D.map3 (\v1 v2 v3 -> { a = v1, b = v2, c = v3 }) (D.field "a" comparable) (D.field "b" b) (D.field "c" c)))
