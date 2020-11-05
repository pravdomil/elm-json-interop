module Utils.TaskUtils exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Task exposing (Task)


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
decodeTask : Decoder a -> Task String Decode.Value -> Task String a
decodeTask decoder a =
    a
        |> Task.andThen
            (\v ->
                v
                    |> Decode.decodeValue decoder
                    |> Result.mapError Decode.errorToString
                    |> resultToTask
            )
