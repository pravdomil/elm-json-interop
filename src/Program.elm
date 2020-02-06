module Program exposing (..)

import Elm.Parser
import Elm.Processing as Processing
import Elm.Syntax.File as Syntax exposing (File)
import Generators.Decode exposing (fromFileToDecoder)
import Generators.Encode exposing (fromFileToEncoder)
import Generators.TypeScript exposing (fromFileToTs)
import Json.Encode exposing (encode, list, string)
import Parser exposing (deadEndsToString)


parse : String -> Result String String
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
            Ok (encode 0 (list string [ fromFileToEncoder file, fromFileToDecoder file, fromFileToTs file ]))
