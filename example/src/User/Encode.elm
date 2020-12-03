module User.Encode exposing (..)

import Json.Encode as E
import User.User as A
import Utils.Basics.Encode as BE


user : A.User -> E.Value
user a =
    case a of
        A.Regular b c ->
            E.object [ ( "type", E.string "Regular" ), ( "a", E.string b ), ( "b", E.int c ) ]

        A.Visitor b ->
            E.object [ ( "type", E.string "Visitor" ), ( "a", E.string b ) ]

        A.Anonymous ->
            E.object [ ( "type", E.string "Anonymous" ) ]
