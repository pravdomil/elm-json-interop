module Example exposing (..)

{-| Example module.
-}


{-| To define what can happen.
-}
type Msg
    = PressedEnter
    | ChangedDraft String
    | ReceivedMessage { user : User, message : String }
    | ClickedExit


{-| To distinguish between users.
-}
type User
    = Regular String Int
    | Visitor String
    | Anonymous