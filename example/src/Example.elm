module Example exposing (..)

{-| Example module.
-}


{-| To define what can happen.
-}
type Msg
    = PressedEnter
    | ChangedDraft String
    | ReceivedMessages (List { user : User, message : Maybe String })
    | ClickedExit


{-| To distinguish between users.
-}
type User
    = Regular String Int
    | Visitor String
    | Anonymous
