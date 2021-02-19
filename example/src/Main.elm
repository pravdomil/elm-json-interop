module Main exposing (..)

import Array
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Msg exposing (..)
import Msg.Decode as MsgDecode
import Msg.Encode as MsgEncode
import Set
import User exposing (..)


{-| -}
msg : Msg
msg =
    let
        ( a, b ) =
            ( Anonymous, "hello" )
    in
    ReceivedMessages
        [ { bool = True
          , int = 1
          , float = 1.2
          , char = 'a'
          , string = "a"

          --
          , unit = ()
          , tuple2 = ( a, b )
          , tuple3 = ( a, b, b )
          , list = [ { a = a, b = b } ]
          , array = Array.fromList [ { a = a, b = b } ]
          , record = {}

          --
          , maybe = Just a
          , result = Ok a

          --
          , set = Set.fromList [ 1 ]
          , dict = Dict.fromList [ ( 1, a ) ]
          }
        ]


{-| -}
test : Result Decode.Error Bool
test =
    msg
        |> MsgEncode.msg
        |> Encode.encode 0
        |> Decode.decodeString MsgDecode.msg
        |> Result.map ((==) msg)
