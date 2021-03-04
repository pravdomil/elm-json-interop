module Sample exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Sample2 exposing (SampleType)
import Set exposing (Set)


type Type0
    = Type0


type Type1
    = Type1 String


type Type2
    = Type2 String String


type Type10
    = Type10 String String String String String String String String String String



--


type alias Record0 =
    {}


type alias Record1 =
    { a1 : String
    }


type alias Record2 =
    { a1 : String
    , a2 : String
    }


type alias Record10 =
    { a1 : String
    , a2 : String
    , a3 : String
    , a4 : String
    , a5 : String
    , a6 : String
    , a7 : String
    , a8 : String
    , a9 : String
    , a10 : String
    }



--


type alias TypeUnqualified =
    SampleType


type alias TypeQualified =
    Sample2.SampleType



--


type alias Sample a b c =
    { -- Sum Types
      unit : ()
    , bool : Bool
    , int : Int
    , float : Float
    , char : Char
    , string : String

    --
    , list : List a
    , array : Array a

    --
    , maybe : Maybe a
    , result : Result a b

    --
    , set : Set a
    , dict : Dict a b

    -- Product Types
    , tuple : ( a, b )
    , tuple3 : ( a, b, c )
    , record : {}
    }
