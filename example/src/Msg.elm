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
    | ReceivedMessages (List (Message User String))
    | ClickedExit



--


{-| -}
type alias Message a b =
    { bool : Bool
    , int : Int
    , float : Float
    , char : Char
    , string : String

    --
    , unit : ()
    , tuple : ( a, b )
    , tuple3 : ( a, b, b )
    , list : List { a : a, b : b }
    , array : Array { a : a, b : b }
    , record : {}

    --
    , maybe : Maybe a
    , result : Result Int a

    --
    , set : Set Int
    , dict : Dict Int a
    }
