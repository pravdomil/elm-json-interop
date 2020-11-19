module Msg exposing (..)

import User exposing (User)


{-| To define what can happen.
-}
type Msg
    = PressedEnter
    | ChangedDraft String
    | ReceivedMessages (List { user : User, message : Maybe String })
    | ClickedExit
