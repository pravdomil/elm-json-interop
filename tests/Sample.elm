module Sample exposing (..)


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
