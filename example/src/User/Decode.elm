module User.Decode exposing (..)

import Json.Decode as D exposing (Decoder)
import User.User as A
import Utils.Basics.Decode as BD


user : Decoder A.User
user =
    D.field "type" D.string
        |> D.andThen
            (\tag ->
                case tag of
                    "Regular" ->
                        D.map2 A.Regular (D.field "a" D.string) (D.field "b" D.int)

                    "Visitor" ->
                        D.map A.Visitor (D.field "a" D.string)

                    "Anonymous" ->
                        D.succeed A.Anonymous

                    _ ->
                        D.fail ("I can't decode " ++ "User" ++ ", unknown tag \"" ++ tag ++ "\".")
            )