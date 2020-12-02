module Generated.Msg.Decode exposing (..)

import Generated.Basics.Decode as BD
import Generated.User.Decode as User exposing (user)
import Json.Decode as D exposing (Decoder)
import Msg as A


msg : Decoder A.Msg
msg =
    D.field "type" D.string
        |> D.andThen
            (\tag ->
                case tag of
                    "PressedEnter" ->
                        D.succeed A.PressedEnter

                    "ChangedDraft" ->
                        D.map A.ChangedDraft (D.field "a" D.string)

                    "ReceivedMessages" ->
                        D.map A.ReceivedMessages (D.field "a" (D.list (example user D.string)))

                    "ClickedExit" ->
                        D.succeed A.ClickedExit

                    _ ->
                        D.fail ("I can't decode " ++ "Msg" ++ ", unknown tag \"" ++ tag ++ "\".")
            )


example aDecoder bDecoder =
    BD.map13 (\a b c d e f g h i j k l m -> { bool = a, int = b, float = c, char = d, string = e, tuple = f, list = g, array = h, record = i, maybe = j, result = k, set = l, dict = m }) (D.field "bool" D.bool) (D.field "int" D.int) (D.field "float" D.float) (D.field "char" BD.char) (D.field "string" D.string) (D.field "tuple" (D.map2 Tuple.pair (D.index 0 aDecoder) (D.index 1 bDecoder))) (D.field "list" (D.list (D.map2 (\a b -> { a = a, b = b }) (D.field "a" aDecoder) (D.field "b" bDecoder)))) (D.field "array" (D.array (D.map2 (\a b -> { a = a, b = b }) (D.field "a" aDecoder) (D.field "b" bDecoder)))) (D.field "record" (D.map2 (\a b -> { a = a, b = b }) (D.field "a" aDecoder) (D.field "b" bDecoder))) (BD.maybeField "maybe" (D.nullable aDecoder)) (D.field "result" (BD.result D.int aDecoder)) (D.field "set" (BD.set D.int)) (D.field "dict" (BD.dict D.int aDecoder))
