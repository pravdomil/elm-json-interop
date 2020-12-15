module Msg.Encode exposing (..)

{-| Generated by elm-json-interop.
-}

import Json.Encode as E
import Msg.Msg as A
import User.Encode as User_User exposing (user)
import Utils.Basics.Encode as BE


msg : A.Msg -> E.Value
msg a =
    case a of
        A.PressedEnter ->
            E.object [ ( "_", E.int 0 ) ]

        A.ChangedDraft b ->
            E.object [ ( "_", E.int 1 ), ( "a", E.string b ) ]

        A.ReceivedMessages b ->
            E.object [ ( "_", E.int 2 ), ( "a", E.list (\b_ -> type_ (\b__ -> user b__) (\b__ -> E.string b__) b_) b ) ]

        A.ClickedExit ->
            E.object [ ( "_", E.int 3 ) ]


type_ encodeA encodeB a =
    E.object [ ( "bool", E.bool a.bool ), ( "int", E.int a.int ), ( "float", E.float a.float ), ( "char", BE.char a.char ), ( "string", E.string a.string ), ( "unit", (\_ -> E.object []) a.unit ), ( "tuple2", (\( a_tuple2_a, a_tuple2_b ) -> E.object [ ( "a", encodeA a_tuple2_a ), ( "b", encodeB a_tuple2_b ) ]) a.tuple2 ), ( "tuple3", (\( a_tuple3_a, a_tuple3_b, a_tuple3_c ) -> E.object [ ( "a", encodeA a_tuple3_a ), ( "b", encodeB a_tuple3_b ), ( "c", encodeB a_tuple3_c ) ]) a.tuple3 ), ( "list", E.list (\a_list_ -> E.object [ ( "a", encodeA a_list_.a ), ( "b", encodeB a_list_.b ) ]) a.list ), ( "array", E.array (\a_array_ -> E.object [ ( "a", encodeA a_array_.a ), ( "b", encodeB a_array_.b ) ]) a.array ), ( "record", E.object [] ), ( "maybe", BE.maybe (\a_maybe_ -> encodeA a_maybe_) a.maybe ), ( "result", BE.result (\a_result_ -> E.int a_result_) (\a_result_ -> encodeA a_result_) a.result ), ( "set", E.set (\a_set_ -> E.int a_set_) a.set ), ( "dict", BE.dict (\a_dict_ -> E.int a_dict_) (\a_dict_ -> encodeA a_dict_) a.dict ) ]
