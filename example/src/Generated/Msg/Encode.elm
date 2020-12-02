module Generated.Msg.Encode exposing (..)

import Msg as A
import Generated.Basics.Encode as BE
import Json.Encode as E
import Generated.User.Encode as User exposing (user)

msg : A.Msg -> E.Value
msg a =
  case a of
    A.PressedEnter -> E.object [ ( "type", E.string "PressedEnter" ) ]
    A.ChangedDraft b -> E.object [ ( "type", E.string "ChangedDraft" ), ( "a", (E.string (b)) ) ]
    A.ReceivedMessages b -> E.object [ ( "type", E.string "ReceivedMessages" ), ( "a", (E.list(\b_ -> (example(\b__ -> (user (b__)) ) (\b__ -> (E.string (b__)) ) (b_)) ) (b)) ) ]
    A.ClickedExit -> E.object [ ( "type", E.string "ClickedExit" ) ]

example t_a t_b a = (E.object [ ( "bool", (E.bool (a.bool)) ), ( "int", (E.int (a.int)) ), ( "float", (E.float (a.float)) ), ( "char", (BE.char (a.char)) ), ( "string", (E.string (a.string)) ), ( "tuple", ((\( a.tuple_a, a.tuple_b ) -> E.list identity [ (t_a (a.tuple_a)), (t_b (a.tuple_b)) ]) (a.tuple)) ), ( "list", (E.list(\a_list_ -> (E.object [ ( "a", (t_a (a_list_.a)) ), ( "b", (t_b (a_list_.b)) ) ]) ) (a.list)) ), ( "array", (E.array(\a_array_ -> (E.object [ ( "a", (t_a (a_array_.a)) ), ( "b", (t_b (a_array_.b)) ) ]) ) (a.array)) ), ( "record", (E.object [ ( "a", (t_a (a.record.a)) ), ( "b", (t_b (a.record.b)) ) ]) ), ( "maybe", (BE.maybe(\a_maybe_ -> (t_a (a_maybe_)) ) (a.maybe)) ), ( "result", (BE.result(\a_result_ -> (E.int (a_result_)) ) (\a_result_ -> (t_a (a_result_)) ) (a.result)) ), ( "set", (E.set(\a_set_ -> (E.int (a_set_)) ) (a.set)) ), ( "dict", (BE.dict(\a_dict_ -> (E.int (a_dict_)) ) (\a_dict_ -> (t_a (a_dict_)) ) (a.dict)) ) ])
