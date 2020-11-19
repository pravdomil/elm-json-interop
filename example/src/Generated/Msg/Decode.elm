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


exampleBool : Decoder A.ExampleBool
exampleBool =
    D.bool


exampleInt : Decoder A.ExampleInt
exampleInt =
    D.int


exampleFloat : Decoder A.ExampleFloat
exampleFloat =
    D.float


exampleString : Decoder A.ExampleString
exampleString =
    D.string


exampleMaybe : Decoder A.ExampleMaybe
exampleMaybe =
    D.nullable D.string


exampleList : Decoder A.ExampleList
exampleList =
    D.list D.string


exampleRecord : Decoder A.ExampleRecord
exampleRecord =
    D.map2 (\a b -> { a = a, b = b }) (D.field "a" D.string) (BD.maybeField "b" (D.nullable D.string))


exampleChar : Decoder A.ExampleChar
exampleChar =
    BD.char


exampleTuple : Decoder A.ExampleTuple
exampleTuple =
    D.map3 (\a b c -> ( a, b, c )) (D.index 0 D.string) (D.index 1 D.string) (D.index 2 D.string)


exampleResult : Decoder A.ExampleResult
exampleResult =
    BD.result D.string D.string


exampleSet : Decoder A.ExampleSet
exampleSet =
    BD.set D.string


exampleDict : Decoder A.ExampleDict
exampleDict =
    BD.dict D.string D.string
