module Example exposing (..)

import Array
import Dict
import Expect
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Sample exposing (..)
import Sample.Decode
import Sample.Encode
import Sample2 exposing (..)
import Set
import Test exposing (..)


suite : Test
suite =
    describe "Coders test."
        [ test_
            "Type0"
            Sample.Encode.type0
            Sample.Decode.type0
            """{"_":0}"""
            Type0
        , test_
            "Type1"
            Sample.Encode.type1
            Sample.Decode.type1
            """{"_":0,"a":"1"}"""
            (Type1 "1")
        , test_
            "Type2"
            Sample.Encode.type2
            Sample.Decode.type2
            """{"_":0,"a":"1","b":"2"}"""
            (Type2 "1" "2")
        , test_
            "Type10"
            Sample.Encode.type10
            Sample.Decode.type10
            """{"_":0,"a":"1","b":"2","c":"3","d":"4","e":"5","f":"6","g":"7","h":"8","i":"9","j":"10"}"""
            (Type10 "1" "2" "3" "4" "5" "6" "7" "8" "9" "10")

        --
        , test_
            "Record0"
            Sample.Encode.record0
            Sample.Decode.record0
            """{}"""
            Record0
        , test_
            "Record1"
            Sample.Encode.record1
            Sample.Decode.record1
            """{"a":"1"}"""
            (Record1 "1")
        , test_
            "Record2"
            Sample.Encode.record2
            Sample.Decode.record2
            """{"a":"1","b":"2"}"""
            (Record2 "1" "2")
        , test_
            "Record10"
            Sample.Encode.record10
            Sample.Decode.record10
            """{"a":"1","b":"2","c":"3","d":"4","e":"5","f":"6","g":"7","h":"8","i":"9","j":"10"}"""
            (Record10 "1" "2" "3" "4" "5" "6" "7" "8" "9" "10")

        --
        , test_
            "TypeQualified"
            Sample.Encode.typeQualified
            Sample.Decode.typeQualified
            """{"_":0}"""
            SampleType
        , test_
            "TypeUnqualified"
            Sample.Encode.typeUnqualified
            Sample.Decode.typeUnqualified
            """{"_":0}"""
            SampleType

        --
        , test_
            "Sample"
            (Sample.Encode.sample Encode.string Encode.string Encode.string)
            (Sample.Decode.sample Decode.string Decode.string Decode.string)
            """{"unit":{},"bool":true,"int":1,"float":3.141592653589793,"char":"a","string":"a","list":["a"],"array":["a"],"maybe":null,"result":{"_":1,"a":"a"},"set":["a"],"dict":[["a","b"]],"tuple":{"a":"a","b":"b"},"tuple3":{"a":"a","b":"b","c":"c"},"record":{}}"""
            (Sample
                ()
                True
                1
                pi
                'a'
                "a"
                [ "a" ]
                (Array.fromList [ "a" ])
                Nothing
                (Err "a")
                (Set.fromList [ "a" ])
                (Dict.fromList [ ( "a", "b" ) ])
                ( "a", "b" )
                ( "a", "b", "c" )
                {}
            )
        ]



--


test_ : String -> (a -> Encode.Value) -> Decoder a -> String -> a -> Test
test_ name encoder decoder snapshot a =
    describe ("Test of " ++ name ++ ".")
        [ test "Value matches encoded and then decoded value." <|
            \_ ->
                Expect.equal (Ok a)
                    (a
                        |> encoder
                        |> Encode.encode 0
                        |> Decode.decodeString decoder
                    )
        , test "Encoded value matches snapshot." <|
            \_ ->
                Expect.equal snapshot
                    (a
                        |> encoder
                        |> Encode.encode 0
                    )
        , test "Decoded snapshot matches value." <|
            \_ ->
                Expect.equal (Ok a)
                    (snapshot
                        |> Decode.decodeString decoder
                    )
        ]
