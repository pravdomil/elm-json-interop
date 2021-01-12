module Interop.JsCode exposing (..)

{-| Part of <https://github.com/pravdomil/Elm-FFI>.
-}

import Json.Decode as Decode
import Task exposing (Task)


{-| To define exception.
-}
type alias Exception =
    String


{-| To run JavaScript code.
-}
eval : String -> Task Exception Decode.Value
eval _ =
    Task.fail "Function is not implemented."
