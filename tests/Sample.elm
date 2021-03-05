module Sample exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Decode as Decode exposing (Value)
import Sample2
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
    { a : String
    }


type alias Record2 =
    { a : String
    , b : String
    }


type alias Record10 =
    { a : String
    , b : String
    , c : String
    , d : String
    , e : String
    , f : String
    , g : String
    , h : String
    , i : String
    , j : String
    }



--


type alias TypeQualified =
    Sample2.SampleType


type alias TypeQualifiedViaAlias =
    Decode.Value


type alias TypeUnqualified =
    Value



--


type alias SampleRecord comparable b c =
    { -- Sum Types
      unit : ()
    , bool : Bool
    , int : Int
    , float : Float
    , char : Char
    , string : String

    --
    , list : List comparable
    , array : Array comparable

    --
    , maybe : Maybe comparable
    , result : Result comparable b

    --
    , set : Set comparable
    , dict : Dict comparable b

    -- Product Types
    , tuple : ( comparable, b )
    , tuple3 : ( comparable, b, c )
    , record : { a : comparable, b : b, c : c }
    }
