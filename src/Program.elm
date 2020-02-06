module Program exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.Syntax.File as Syntax exposing (File)
import Generators.Decode exposing (fromFileToDecoder)
import Generators.Encode exposing (fromFileToEncoder)
import Generators.TypeScript exposing (fromFileToTs)
import Json.Encode exposing (Value, list, string)
import Parser exposing (deadEndsToString)


parse : String -> Result String Value
parse input =
    case Elm.Parser.parse input of
        Err e ->
            Err ("I can't parse input elm file.\n" ++ deadEndsToString e)

        Ok a ->
            let
                file : Syntax.File
                file =
                    Processing.process Processing.init a
            in
            Ok (list string [ fromFileToEncoder file, fromFileToDecoder file, fromFileToTs file ])
