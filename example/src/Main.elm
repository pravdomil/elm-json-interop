module Main exposing (..)

import Array
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Msg exposing (..)
import Msg.Decode
import Msg.Encode
import Set
import User exposing (..)


test : Result Decode.Error Bool
test =
    sample
        |> Msg.Encode.msg
        |> Encode.encode 0
        |> Decode.decodeString Msg.Decode.msg
        |> Result.map ((==) sample)


sample : Msg
sample =
    ReceivedMessages
        [ message
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
