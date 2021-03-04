module Example exposing (..)

import Array
import Dict
import Expect
import Json.Decode as Decode
import Json.Encode as Encode
import Sample exposing (..)
import Sample2 exposing (..)
import Set
import Test exposing (..)


suite : Test
suite =
    describe "Sample test."
        [ test "Encodes and decodes sample." <|
            \_ ->
                Expect.equal (Ok True)
                    (sample
                        |> Msg.Encode.msg
                        |> Encode.encode 0
                        |> Decode.decodeString Msg.Decode.msg
                        |> Result.map ((==) sample)
                    )
        , test "Snapshot matches sample." <|
            \_ ->
                Expect.equal (Ok sample)
                    (snapshot
                        |> Decode.decodeString Msg.Decode.msg
                    )
        , test "Sample matches snapshot." <|
            \_ ->
                Expect.equal snapshot
                    (sample
                        |> Msg.Encode.msg
                        |> Encode.encode 2
                    )
        ]


type0 : Type0
type0 =
    Type0


type1 : Type1
type1 =
    Type1 "a1"


type2 : Type2
type2 =
    Type2 "a1" "a2"


type10 : Type10
type10 =
    Type10 "a1" "a2" "a3" "a4" "a5" "a6" "a7" "a8" "a9" "a10"


record0 : Record0
record0 =
    Record0


record1 : Record1
record1 =
    Record1 "a1"


record2 : Record2
record2 =
    Record2 "a1" "a2"


record10 : Record10
record10 =
    Record10 "a1" "a2" "a3" "a4" "a5" "a6" "a7" "a8" "a9" "a10"


typeQualified : TypeQualified
typeQualified =
    SampleType


typeUnqualified : TypeUnqualified
typeUnqualified =
    SampleType


sample : Sample String String String
sample =
    { -- Sum Types
      unit = ()
    , bool = True
    , int = 1
    , float = pi
    , char = 'a'
    , string = "a"

    --
    , list = [ "a" ]
    , array = Array.fromList [ "a" ]

    --
    , maybe = Just "a"
    , result = Ok "a"

    --
    , set = Set.fromList [ "a" ]
    , dict = Dict.fromList [ ( "a", "b" ) ]

    -- Product Types
    , tuple = ( "a", "b" )
    , tuple3 = ( "a", "b", "c" )
    , record = {}
    }



--


snapshot : String
snapshot =
    """{
  "_": 2,
  "a": [
    {
      "a": {
        "_": 0,
        "a": "1"
      },
      "b": {
        "bool": true,
        "int": 1,
        "float": 3.141592653589793,
        "char": "a",
        "string": "a",
        "unit": {},
        "tuple": {
          "a": {
            "_": 2
          },
          "b": "hello"
        },
        "tuple3": {
          "a": {
            "_": 2
          },
          "b": "hello",
          "c": "hello"
        },
        "list": [
          {
            "a": {
              "_": 2
            },
            "b": "hello"
          }
        ],
        "array": [
          {
            "a": {
              "_": 2
            },
            "b": "hello"
          }
        ],
        "record": {},
        "maybe": {
          "_": 2
        },
        "result": {
          "_": 0,
          "a": {
            "_": 2
          }
        },
        "set": [
          1
        ],
        "dict": [
          [
            1,
            {
              "_": 2
            }
          ]
        ]
      }
    }
  ]
}"""
