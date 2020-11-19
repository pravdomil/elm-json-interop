module Generated.Example.Encode exposing (..)

import Example as A
import Generated.Basics.Encode exposing (..)
import Json.Encode exposing (..)


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


user : A.User -> Value
user a =
    case a of
        A.Regular b c ->
            list identity [ string "Regular", string b, int c ]

        A.Visitor b ->
            list identity [ string "Visitor", string b ]

        A.Anonymous ->
            list identity [ string "Anonymous" ]
