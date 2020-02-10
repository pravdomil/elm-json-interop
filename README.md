# Elm JSON Interop

## Usage

```sh
npm i pravdomil/elm-json-interop -g
elm-json-interop "src/Main.elm"
# Generates: src/Main/Encode.elm, src/Main/Decode.elm, src/Main/Main.ts
```

## Example

input file Main.elm
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

generated Main/Main.ts
```ts
export type Maybe<a> = a | null

export type Msg =
  | { PressedEnter: [] }
  | { ChangedDraft: string }
  | { ReceivedMessage: { user: User, message: string } }
  | { ClickedExit: [] }

export const isPressedEnter = (a: Msg): a is { PressedEnter: [] } => "PressedEnter" in a
export const isChangedDraft = (a: Msg): a is { ChangedDraft: string } => "ChangedDraft" in a
export const isReceivedMessage = (a: Msg): a is { ReceivedMessage: { user: User, message: string } } => "ReceivedMessage" in a
export const isClickedExit = (a: Msg): a is { ClickedExit: [] } => "ClickedExit" in a

export type User =
  | { Regular: [string, number] }
  | { Visitor: string }
  | { Anonymous: [] }

export const isRegular = (a: User): a is { Regular: [string, number] } => "Regular" in a
export const isVisitor = (a: User): a is { Visitor: string } => "Visitor" in a
export const isAnonymous = (a: User): a is { Anonymous: [] } => "Anonymous" in a
```

generated Main/Encode.elm
```elm
module Main.Encode exposing (..)

import Main exposing (..)
import Json.Encode exposing (..)

encodeMaybe a b = case b of
   Just c -> a c
   Nothing -> null

encodeDict _ b c = dict identity b c

encodeMsg : Msg -> Value
encodeMsg a =
  case a of
    PressedEnter -> object [ ( "PressedEnter", list identity [] ) ]
    ChangedDraft b -> object [ ( "ChangedDraft", string b ) ]
    ReceivedMessage b -> object [ ( "ReceivedMessage", object [ ( "user", encodeUser b.user ), ( "message", string b.message ) ] ) ]
    ClickedExit -> object [ ( "ClickedExit", list identity [] ) ]

encodeUser : User -> Value
encodeUser a =
  case a of
    Regular b c -> object [ ( "Regular", list identity [ string b, int c ] ) ]
    Visitor b -> object [ ( "Visitor", string b ) ]
    Anonymous -> object [ ( "Anonymous", list identity [] ) ]
```

generated Main/Decode.elm
```elm
module Main.Decode exposing (..)

import Json.Decode exposing (..)
import Main exposing (..)
import Set


decodeSet a =
    map Set.fromList (list a)


decodeDict _ a =
    dict a


decodeMsg : Decoder Msg
decodeMsg =
    oneOf
        [ field "PressedEnter" (succeed PressedEnter)
        , field "ChangedDraft" (map ChangedDraft string)
        , field "ReceivedMessage" (map ReceivedMessage (map2 (\a b -> { user = a, message = b }) (field "user" decodeUser) (field "message" string)))
        , field "ClickedExit" (succeed ClickedExit)
        ]


decodeUser : Decoder User
decodeUser =
    oneOf
        [ field "Regular" (map2 Regular (index 0 string) (index 1 int))
        , field "Visitor" (map Visitor string)
        , field "Anonymous" (succeed Anonymous)
        ]
```
