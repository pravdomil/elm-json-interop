module Generated.User.Encode exposing (..)

import Generated.Basics.Encode as BE
import Json.Encode as E
import User as A


user : A.User -> E.Value
user a =
    case a of
        A.Regular b c ->
            E.list identity [ E.string "Regular", E.string b, E.int c ]

        A.Visitor b ->
            E.list identity [ E.string "Visitor", E.string b ]

        A.Anonymous ->
            E.list identity [ E.string "Anonymous" ]
