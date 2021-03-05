module Generators.Argument exposing (..)

import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.Pattern exposing (Pattern(..))


type Argument
    = Argument Int


toString : Argument -> String
toString (Argument a) =
    "v" ++ String.fromInt (a + 1)


toPattern : Argument -> Pattern
toPattern a =
    VarPattern (toString a)


toExpression : Argument -> Expression
toExpression a =
    FunctionOrValue [] (toString a)
