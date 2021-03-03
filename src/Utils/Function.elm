module Utils.Function exposing (..)

import Utils.String_ as String_


nameFromString : String -> String
nameFromString a =
    a
        |> String_.firstToLower
        |> (\v ->
                if v |> isElmKeyword then
                    v ++ "_"

                else
                    v
           )


isElmKeyword : String -> Bool
isElmKeyword a =
    List.member a elmKeywords


elmKeywords : List String
elmKeywords =
    [ "module"
    , "where"
    , "import"
    , "as"
    , "exposing"
    , "if"
    , "then"
    , "else"
    , "case"
    , "of"
    , "let"
    , "in"
    , "type"
    , "port"
    , "infix"
    ]
