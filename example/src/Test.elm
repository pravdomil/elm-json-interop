module Test exposing (..)

import Generated.Msg.Decode as MsgDecode
import Generated.Msg.Encode as MsgEncode
import Json.Decode as Decode
import Json.Encode as Encode
import Msg exposing (Msg(..))
import User exposing (User(..))


{-| -}
msg : Msg
msg =
    ReceivedMessages
        [ { user = Visitor "Paul", message = Nothing }
        ]


{-| -}
test : Result Decode.Error Bool
test =
    msg
        |> MsgEncode.msg
        |> Encode.encode 0
        |> Decode.decodeString MsgDecode.msg
        |> Result.map ((==) msg)
