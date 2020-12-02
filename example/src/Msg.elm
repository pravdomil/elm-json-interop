module Msg exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Set exposing (Set)
import User exposing (User)


{-| To define what can happen.
-}
type Msg
    = PressedEnter
    | ChangedDraft String
    | ReceivedMessages (List (Example User String))
    | ClickedExit



--


{-| -}
type alias Example a b =
    { bool : Bool
    , int : Int
    , float : Float
    , char : Char
    , string : String

    --
    , tuple : ( a, b )
    , list : List { a : a, b : b }
    , array : Array { a : a, b : b }
    , record : { a : a, b : b }

    --
    , maybe : Maybe a
    , result : Result Int a

    --
    , set : Set Int
    , dict : Dict Int a
    }
