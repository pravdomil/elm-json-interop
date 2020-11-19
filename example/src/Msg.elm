module Msg exposing (..)

import Dict exposing (Dict)
import Set exposing (Set)
import User exposing (User)


{-| To define what can happen.
-}
type Msg
    = PressedEnter
    | ChangedDraft String
    | ReceivedMessages (List { user : User, message : Maybe String })
    | ClickedExit



--


{-| -}
type alias ExampleBool =
    Bool


{-| -}
type alias ExampleInt =
    Int


{-| -}
type alias ExampleFloat =
    Float


{-| -}
type alias ExampleString =
    String


{-| -}
type alias ExampleMaybe =
    Maybe String


{-| -}
type alias ExampleList =
    List String


{-| -}
type alias ExampleRecord =
    { a : String
    , b : Maybe String
    }



--


{-| -}
type alias ExampleChar =
    Char


{-| -}
type alias ExampleTuple =
    ( String, String, String )


{-| -}
type alias ExampleResult =
    Result String String



--


{-| -}
type alias ExampleSet =
    Set String


{-| -}
type alias ExampleDict =
    Dict String String
