module Generated.ExampleDecode exposing (..)

import Example as A
import Generated.Basics.BasicsDecode exposing (..)
import Json.Decode exposing (..)


msgDecoder : Decoder A.Msg
msgDecoder =
    index 0 string
        |> andThen
            (\tag ->
                case tag of
                    "PressedEnter" ->
                        succeed A.PressedEnter

                    "ChangedDraft" ->
                        map A.ChangedDraft (index 1 string)

                    "ReceivedMessages" ->
                        map A.ReceivedMessages (index 1 (list (map2 (\a b -> { user = a, message = b }) (field "user" userDecoder) (field "message" string))))

                    "ClickedExit" ->
                        succeed A.ClickedExit

                    _ ->
                        fail ("I can't decode " ++ "Msg" ++ ", what " ++ tag ++ " means?")
            )


userDecoder : Decoder A.User
userDecoder =
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
                        fail ("I can't decode " ++ "User" ++ ", what " ++ tag ++ " means?")
            )
