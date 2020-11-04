module Eval exposing (..)

{-| Read <https://guide.elm-lang.org/interop/limits.html>
-}

import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


{-| To define error.
-}
type alias Error =
    String


{-| To create command line program.
-}
cliProgram : Cmd msg -> Program flags () msg
cliProgram init =
    Platform.worker
        { init = \_ -> ( (), init )
        , update = \_ _ -> ( (), Cmd.none )
        , subscriptions = \_ -> Sub.none
        }



--


{-| To run JavaScript code. Function implementation gets replaced by actual function in build step.
-}
jsCode : String -> Task String Decode.Value
jsCode _ =
    Task.fail "Function is not implemented."



--


{-| To get program arguments.
-}
getArguments : Task Error (List String)
getArguments =
    jsCode "process.argv"
        |> decodeTaskValue (Decode.list Decode.string)


{-| To get stdin.
-}
getStdin : Task Error (Maybe String)
getStdin =
    jsCode "process.stdin.isTTY ? null : require('fs').readFileSync(0, 'utf8')"
        |> decodeTaskValue (Decode.maybe Decode.string)



--


{-| To call console.log function.
-}
consoleLog : String -> Task Error ()
consoleLog _ =
    jsCode "console.log(_v0)"
        |> decodeTaskValue (Decode.succeed ())


{-| To call console.error function.
-}
consoleError : String -> Task Error ()
consoleError _ =
    jsCode "console.error(_v0)"
        |> decodeTaskValue (Decode.succeed ())


{-| To kill process with exit code.
-}
processExit : Int -> Task Error ()
processExit _ =
    jsCode "process.exit(_v0)"
        |> decodeTaskValue (Decode.succeed ())



--


{-| To get \_\_filename.
-}
filename__ : Task Error String
filename__ =
    jsCode "__filename"
        |> decodeTaskValue Decode.string


{-| To get \_\_dirname.
-}
dirname__ : Task Error String
dirname__ =
    jsCode "__dirname"
        |> decodeTaskValue Decode.string


{-| To get real path.
-}
realPath : String -> Task Error String
realPath _ =
    jsCode "require('fs').realpathSync(_v0, 'utf8')"
        |> decodeTaskValue Decode.string



--


{-| To create directory recursively.
-}
mkDir : String -> Task Error ()
mkDir _ =
    jsCode "require('fs').mkdirSync(_v0, { recursive: true })"
        |> decodeTaskValue (Decode.succeed ())


{-| To read file.
-}
readFile : String -> Task Error String
readFile _ =
    jsCode "require('fs').readFileSync(_v0, 'utf8')"
        |> decodeTaskValue Decode.string


{-| To write file.
-}
writeFile : String -> String -> Task Error ()
writeFile _ _ =
    jsCode "require('fs').writeFileSync(_v0, _v1)"
        |> decodeTaskValue (Decode.succeed ())


{-| To copy file.
-}
copyFile : String -> String -> Task Error ()
copyFile _ _ =
    jsCode "require('fs').copyFileSync(_v0, _v1)"
        |> decodeTaskValue (Decode.succeed ())



--


{-| -}
taskAndThen2 : (a -> b -> Task x result) -> Task x a -> Task x b -> Task x result
taskAndThen2 func taskA taskB =
    taskA
        |> Task.andThen
            (\a ->
                taskB
                    |> Task.andThen (\b -> func a b)
            )


{-| -}
taskAndThen3 : (a -> b -> c -> Task x result) -> Task x a -> Task x b -> Task x c -> Task x result
taskAndThen3 func taskA taskB taskC =
    taskA
        |> Task.andThen
            (\a ->
                taskB
                    |> Task.andThen
                        (\b ->
                            taskC
                                |> Task.andThen (\c -> func a b c)
                        )
            )


{-| -}
taskAndThen4 : (a -> b -> c -> d -> Task x result) -> Task x a -> Task x b -> Task x c -> Task x d -> Task x result
taskAndThen4 func taskA taskB taskC taskD =
    taskA
        |> Task.andThen
            (\a ->
                taskB
                    |> Task.andThen
                        (\b ->
                            taskC
                                |> Task.andThen
                                    (\c ->
                                        taskD
                                            |> Task.andThen (\d -> func a b c d)
                                    )
                        )
            )


{-| -}
taskAndThen5 : (a -> b -> c -> d -> e -> Task x result) -> Task x a -> Task x b -> Task x c -> Task x d -> Task x e -> Task x result
taskAndThen5 func taskA taskB taskC taskD taskE =
    taskA
        |> Task.andThen
            (\a ->
                taskB
                    |> Task.andThen
                        (\b ->
                            taskC
                                |> Task.andThen
                                    (\c ->
                                        taskD
                                            |> Task.andThen
                                                (\d ->
                                                    taskE
                                                        |> Task.andThen (\e -> func a b c d e)
                                                )
                                    )
                        )
            )



--


{-| -}
maybeToTask : x -> Maybe a -> Task x a
maybeToTask x a =
    case a of
        Just b ->
            Task.succeed b

        Nothing ->
            Task.fail x


{-| -}
resultToTask : Result x a -> Task x a
resultToTask a =
    case a of
        Ok b ->
            Task.succeed b

        Err b ->
            Task.fail b



--


{-| -}
decodeTaskValue : Decoder a -> Task String Decode.Value -> Task String a
decodeTaskValue decoder a =
    a
        |> Task.andThen
            (\v ->
                v
                    |> Decode.decodeValue decoder
                    |> Result.mapError Decode.errorToString
                    |> resultToTask
            )
