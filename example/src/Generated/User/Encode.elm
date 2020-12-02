module Generated.User.Encode exposing (..)

import User as A
import Generated.Basics.Encode as BE
import Json.Encode as E


user : A.User -> E.Value
user a =
  case a of
    A.Regular b c -> E.object [ ( "type", E.string "Regular" ), ( "a", (E.string (b)) ), ( "b", (E.int (c)) ) ]
    A.Visitor b -> E.object [ ( "type", E.string "Visitor" ), ( "a", (E.string (b)) ) ]
    A.Anonymous -> E.object [ ( "type", E.string "Anonymous" ) ]
