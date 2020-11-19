module Generated.Msg.Encode exposing (..)

import Generated.Basics.Encode exposing (..)
import Generated.User.Encode exposing (user)
import Json.Encode exposing (..)
import Msg as A


msg : A.Msg -> Value
msg a =
    case a of
        A.PressedEnter ->
            list identity [ string "PressedEnter" ]

        A.ChangedDraft b ->
            list identity [ string "ChangedDraft", string b ]

        A.ReceivedMessages b ->
            list identity [ string "ReceivedMessages", list (\b_ -> object [ ( "user", user b_.user ), ( "message", maybe (\b__message_ -> string b__message_) b_.message ) ]) b ]

        A.ClickedExit ->
            list identity [ string "ClickedExit" ]
