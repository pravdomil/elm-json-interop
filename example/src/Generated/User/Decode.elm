module Generated.User.Decode exposing (..)

import Generated.Basics.Decode as BD
import Json.Decode as D exposing (Decoder)
import User as A


user : Decoder A.User
user =
    D.index 0 D.string
        |> D.andThen
            (\tag ->
                case tag of
                    "Regular" ->
                        D.map2 A.Regular (D.index 1 D.string) (D.index 2 D.int)

                    "Visitor" ->
                        D.map A.Visitor (D.index 1 D.string)

                    "Anonymous" ->
                        D.succeed A.Anonymous

                    _ ->
                        D.fail ("I can't decode " ++ "User" ++ ", unknown tag \"" ++ tag ++ "\".")
            )
