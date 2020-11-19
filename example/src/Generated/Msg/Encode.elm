module Generated.Msg.Encode exposing (..)

import Generated.Basics.Encode as BE
import Generated.User.Encode exposing (user)
import Json.Encode as E
import Msg as A


msg : A.Msg -> E.Value
msg a =
    case a of
        A.PressedEnter ->
            E.list identity [ E.string "PressedEnter" ]

        A.ChangedDraft b ->
            E.list identity [ E.string "ChangedDraft", E.string b ]

        A.ReceivedMessages b ->
            E.list identity [ E.string "ReceivedMessages", E.list (\b_ -> E.object [ ( "user", user b_.user ), ( "message", maybe (\b__message_ -> E.string b__message_) b_.message ) ]) b ]

        A.ClickedExit ->
            E.list identity [ E.string "ClickedExit" ]
