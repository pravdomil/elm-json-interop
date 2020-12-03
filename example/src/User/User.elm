module User.User exposing (..)

{-| -}


{-| To distinguish between users.
-}
type User
    = Regular String Int
    | Visitor String
    | Anonymous
