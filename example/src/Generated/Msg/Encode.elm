module Generated.Msg.Encode exposing (..)

import Generated.Basics.Encode as BE
import Generated.User.Encode as User exposing (user)
import Json.Encode as E
import Msg as A


msg : A.Msg -> E.Value
msg a =
    case a of
        A.PressedEnter ->
            E.list identity [ E.string "PressedEnter" ]

        A.ChangedDraft b ->
            E.list identity [ E.string "ChangedDraft", E.string b ]

        A.ReceivedMessages b ->
            E.list identity [ E.string "ReceivedMessages", E.list (\b_ -> E.object [ ( "user", user b_.user ), ( "message", BE.maybe (\b__message_ -> E.string b__message_) b_.message ) ]) b ]

        A.ClickedExit ->
            E.list identity [ E.string "ClickedExit" ]


exampleBool : A.ExampleBool -> E.Value
exampleBool a =
    E.bool a


exampleInt : A.ExampleInt -> E.Value
exampleInt a =
    E.int a


exampleFloat : A.ExampleFloat -> E.Value
exampleFloat a =
    E.float a


exampleString : A.ExampleString -> E.Value
exampleString a =
    E.string a


exampleMaybe : A.ExampleMaybe -> E.Value
exampleMaybe a =
    BE.maybe (\a_ -> E.string a_) a


exampleList : A.ExampleList -> E.Value
exampleList a =
    E.list (\a_ -> E.string a_) a


exampleRecord : A.ExampleRecord -> E.Value
exampleRecord a =
    E.object [ ( "a", E.string a.a ), ( "b", BE.maybe (\a_b_ -> E.string a_b_) a.b ) ]


exampleChar : A.ExampleChar -> E.Value
exampleChar a =
    BE.char a


exampleTuple : A.ExampleTuple -> E.Value
exampleTuple a =
    (\( a_a, a_b, a_c ) -> E.list identity [ E.string a_a, E.string a_b, E.string a_c ]) a


exampleResult : A.ExampleResult -> E.Value
exampleResult a =
    BE.result (\a_ -> E.string a_) (\a_ -> E.string a_) a


exampleSet : A.ExampleSet -> E.Value
exampleSet a =
    E.set (\a_ -> E.string a_) a


exampleDict : A.ExampleDict -> E.Value
exampleDict a =
    BE.dict (\a_ -> E.string a_) (\a_ -> E.string a_) a
