module Generated.User.Encode exposing (..)

import Generated.Basics.Encode exposing (..)
import Json.Encode exposing (..)
import User as A


user : A.User -> Value
user a =
    case a of
        A.Regular b c ->
            list identity [ string "Regular", string b, int c ]

        A.Visitor b ->
            list identity [ string "Visitor", string b ]

        A.Anonymous ->
            list identity [ string "Anonymous" ]
