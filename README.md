# Elm JSON Interop

## Usage

```sh
npm i pravdomil/elm-json-interop -g
elm-json-interop "src/Main.elm"
# Generates: src/Main/Encode.elm, src/Main/Decode.elm, src/Main/Main.ts
```

## Example

**Main.elm**
```elm
module Main exposing (..)


type Msg
    = PressedEnter
    | ChangedDraft String
    | ReceivedMessage { user : User, message : String }
    | ClickedExit


type User
    = Regular String Int
    | Visitor String
    | Anonymous
```

**Main/Main.ts**
```ts
export type Maybe<a> = a | null

export type Msg =
  | ["PressedEnter"]
  | ["ChangedDraft", string]
  | ["ReceivedMessage", { user: User, message: string }]
  | ["ClickedExit"]

export type User =
  | ["Regular", string, number]
  | ["Visitor", string]
  | ["Anonymous"]
```

**Main/Encode.elm**
```elm
module Main.Encode exposing (..)

import Main exposing (..)
import Json.Encode exposing (..)


encodeMaybe a b =
    case b of
        Just c ->
            a c

        Nothing ->
            null


encodeDict _ b c =
    dict identity b c


encodeMsg : Msg -> Value
encodeMsg a =
    case a of
        PressedEnter ->
            list identity [ string "PressedEnter" ]

        ChangedDraft b ->
            list identity [ string "ChangedDraft", string b ]

        ReceivedMessage b ->
            list identity [ string "ReceivedMessage", object [ ( "user", encodeUser b.user ), ( "message", string b.message ) ] ]

        ClickedExit ->
            list identity [ string "ClickedExit" ]


encodeUser : User -> Value
encodeUser a =
    case a of
        Regular b c ->
            list identity [ string "Regular", string b, int c ]

        Visitor b ->
            list identity [ string "Visitor", string b ]

        Anonymous ->
            list identity [ string "Anonymous" ]
```

**Main/Decode.elm**
```elm
module Main.Decode exposing (..)

import Main exposing (..)
import Json.Decode exposing (..)
import Set


decodeSet a =
    map Set.fromList (list a)


decodeDict _ a =
    dict a


decodeMsg : Decoder Msg
decodeMsg =
    index 0 string
        |> andThen
            (\tag ->
                case tag of
                    "PressedEnter" ->
                        succeed PressedEnter

                    "ChangedDraft" ->
                        map ChangedDraft (index 1 string)

                    "ReceivedMessage" ->
                        map ReceivedMessage (index 1 (map2 (\a b -> { user = a, message = b }) (field "user" decodeUser) (field "message" string)))

                    "ClickedExit" ->
                        succeed ClickedExit

                    _ ->
                        fail <| "I can't decode " ++ "Msg" ++ ", what " ++ tag ++ " means?"
            )


decodeUser : Decoder User
decodeUser =
    index 0 string
        |> andThen
            (\tag ->
                case tag of
                    "Regular" ->
                        map2 Regular (index 1 string) (index 2 int)

                    "Visitor" ->
                        map Visitor (index 1 string)

                    "Anonymous" ->
                        succeed Anonymous

                    _ ->
                        fail <| "I can't decode " ++ "User" ++ ", what " ++ tag ++ " means?"
            )
```
