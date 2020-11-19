module Generated.User.Decode exposing (..)

import Generated.Basics.Decode exposing (..)
import Json.Decode exposing (..)
import User as A


user : Decoder A.User
user =
    index 0 string
        |> andThen
            (\tag ->
                case tag of
                    "Regular" ->
                        map2 A.Regular (index 1 string) (index 2 int)

                    "Visitor" ->
                        map A.Visitor (index 1 string)

                    "Anonymous" ->
                        succeed A.Anonymous

                    _ ->
                        fail ("I can't decode " ++ "User" ++ ", unknown tag \"" ++ tag ++ "\".")
            )
