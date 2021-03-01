module Id exposing (..)


type Id
    = Id String


fromString : String -> Id
fromString =
    Id


toString : Id -> String
toString (Id a) =
    a
