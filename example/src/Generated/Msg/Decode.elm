module Generated.Msg.Decode exposing (..)

import Generated.Basics.Decode exposing (..)
import Generated.UserDecode exposing (user)
import Json.Decode exposing (..)
import Msg as A


msg : Decoder A.Msg
msg =
    index 0 string
        |> andThen
            (\tag ->
                case tag of
                    "PressedEnter" ->
                        succeed A.PressedEnter

                    "ChangedDraft" ->
                        map A.ChangedDraft (index 1 string)

                    "ReceivedMessages" ->
                        map A.ReceivedMessages (index 1 (list (map2 (\a b -> { user = a, message = b }) (field "user" user) (maybeField "message" (nullable string)))))

                    "ClickedExit" ->
                        succeed A.ClickedExit

                    _ ->
                        fail ("I can't decode " ++ "Msg" ++ ", unknown tag \"" ++ tag ++ "\".")
            )
