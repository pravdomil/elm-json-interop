module Utils.Argument exposing (..)

import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.Pattern exposing (Pattern(..))


type Argument
    = Argument Int


next : Argument -> Argument
next (Argument a) =
    Argument (a + 1)


toString : Argument -> String
toString (Argument a) =
    "v" ++ String.fromInt (a + 1)


toPattern : Argument -> Pattern
toPattern a =
    VarPattern (toString a)


toExpression : Argument -> Expression
toExpression a =
    FunctionOrValue [] (toString a)
