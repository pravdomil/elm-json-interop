module Example exposing (..)

import Array
import Dict
import Expect
import Id
import Json.Decode as Decode
import Json.Encode as Encode
import Msg exposing (..)
import Msg.Decode
import Msg.Encode
import Set
import Test exposing (..)
import User exposing (..)


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


sample : Msg
sample =
    ReceivedMessages
        [ ( Id.fromString "1", message )
        ]


message : Message User String
message =
    let
        ( a, b ) =
            ( Anonymous, "hello" )
    in
    { -- Sum Types
      unit = ()
    , bool = True
    , int = 1
    , float = pi
    , char = 'a'
    , string = "a"

    --
    , list = [ { a = a, b = b } ]
    , array = Array.fromList [ { a = a, b = b } ]

    --
    , maybe = Just a
    , result = Ok a

    --
    , set = Set.fromList [ 1 ]
    , dict = Dict.fromList [ ( 1, a ) ]

    -- Product Types
    , tuple = ( a, b )
    , tuple3 = ( a, b, b )
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
