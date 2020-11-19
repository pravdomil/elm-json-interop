module Generated.Example.Encode exposing (..)

import Example as A
import Generated.Basics.Encode exposing (..)
import Json.Encode exposing (..)


encodeMsg : A.Msg -> Value
encodeMsg a =
    case a of
        A.PressedEnter ->
            list identity [ string "PressedEnter" ]

        A.ChangedDraft b ->
            list identity [ string "ChangedDraft", string b ]

        A.ReceivedMessages b ->
            list identity [ string "ReceivedMessages", list (\b_ -> object [ ( "user", encodeUser b_.user ), ( "message", encodeMaybe (\b__message_ -> string b__message_) b_.message ) ]) b ]

        A.ClickedExit ->
            list identity [ string "ClickedExit" ]


encodeUser : A.User -> Value
encodeUser a =
    case a of
        A.Regular b c ->
            list identity [ string "Regular", string b, int c ]

        A.Visitor b ->
            list identity [ string "Visitor", string b ]

        A.Anonymous ->
            list identity [ string "Anonymous" ]
