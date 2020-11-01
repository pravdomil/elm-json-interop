module Generated.ExampleEncode exposing (..)

import Example as A
import Generated.Basics.BasicsEncode exposing (..)
import Json.Encode exposing (..)


encodeMsg : A.Msg -> Value
encodeMsg a =
    case a of
        A.PressedEnter ->
            list identity [ string "PressedEnter" ]

        A.ChangedDraft b ->
            list identity [ string "ChangedDraft", string b ]

        A.ReceivedMessage b ->
            list identity [ string "ReceivedMessage", object [ ( "user", encodeUser b.user ), ( "message", string b.message ) ] ]

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
