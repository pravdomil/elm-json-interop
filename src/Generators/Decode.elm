module Generators.Decode exposing (fromFile)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.File exposing (File)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Module as Module exposing (Module(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Range as Range
import Elm.Writer as Writer
import Generators.Imports as Imports


fromFile : File -> String
fromFile a =
    let
        suffix : String
        suffix =
            "Decode"

        name : ModuleName
        name =
            a.moduleDefinition |> Node.value |> Module.moduleName

        module_ : Node Module
        module_ =
            NormalModule
                { moduleName = n (name ++ [ suffix ])
                , exposingList = n (All Range.emptyRange)
                }
                |> n

        imports : List (Node Import)
        imports =
            a |> Imports.fromFile suffix |> (++) (additionalImports name)

        declarations : List (Node Declaration)
        declarations =
            []
    in
    { a
        | moduleDefinition = module_
        , imports = imports
        , declarations = declarations
    }
        |> Writer.writeFile
        |> Writer.write


additionalImports : ModuleName -> List (Node Import)
additionalImports a =
    let
        import_ : ModuleName -> String -> Import
        import_ b c =
            Import (n b) (Just (n [ c ])) Nothing

        importExposingType : ModuleName -> String -> String -> Import
        importExposingType b c d =
            Import (n b) (Just (n [ c ])) (Just (n (Explicit [ n (TypeOrAliasExpose d) ])))
    in
    [ import_ a "A"
    , importExposingType [ "Json", "Decode" ] "D" "Decoder"
    , import_ [ "Utils", "Json", "Decode_" ] "D_"
    ]
        |> List.map n



--


n : a -> Node a
n =
    Node Range.emptyRange
