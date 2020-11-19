module Generated.Msg.Decode exposing (..)

import Generated.Basics.Decode as BD
import Generated.User.Decode exposing (user)
import Json.Decode as D exposing (Decoder)
import Msg as A


msg : Decoder A.Msg
msg =
    D.index 0 D.string
        |> D.andThen
            (\tag ->
                case tag of
                    "PressedEnter" ->
                        D.succeed A.PressedEnter

                    "ChangedDraft" ->
                        D.map A.ChangedDraft (D.index 1 D.string)

                    "ReceivedMessages" ->
                        D.map A.ReceivedMessages (D.index 1 (D.list (D.map2 (\a b -> { user = a, message = b }) (D.field "user" user) (BD.maybeField "message" (D.nullable D.string)))))

                    "ClickedExit" ->
                        D.succeed A.ClickedExit

                    _ ->
                        D.fail ("I can't decode " ++ "Msg" ++ ", unknown tag \"" ++ tag ++ "\".")
            )
