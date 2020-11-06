module Utils.TaskUtils exposing (..)

{-| <https://github.com/avh4/elm-format/issues/568#issuecomment-554753735>
-}

import Json.Decode as Decode exposing (Decoder)
import Task exposing (..)


{-| -}
taskAndThen2 : (a -> b -> Task x result) -> Task x a -> Task x b -> Task x result
taskAndThen2 func taskA taskB =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen (\b -> func a b)
            )


{-| -}
taskAndThen3 : (a -> b -> c -> Task x result) -> Task x a -> Task x b -> Task x c -> Task x result
taskAndThen3 func taskA taskB taskC =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen (\c -> func a b c)
                        )
            )


{-| -}
taskAndThen4 : (a -> b -> c -> d -> Task x result) -> Task x a -> Task x b -> Task x c -> Task x d -> Task x result
taskAndThen4 func taskA taskB taskC taskD =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen
                                    (\c ->
                                        taskD
                                            |> andThen (\d -> func a b c d)
                                    )
                        )
            )


{-| -}
taskAndThen5 : (a -> b -> c -> d -> e -> Task x result) -> Task x a -> Task x b -> Task x c -> Task x d -> Task x e -> Task x result
taskAndThen5 func taskA taskB taskC taskD taskE =
    taskA
        |> andThen
            (\a ->
                taskB
                    |> andThen
                        (\b ->
                            taskC
                                |> andThen
                                    (\c ->
                                        taskD
                                            |> andThen
                                                (\d ->
                                                    taskE
                                                        |> andThen (\e -> func a b c d e)
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
            succeed b

        Nothing ->
            fail x


{-| -}
resultToTask : Result x a -> Task x a
resultToTask a =
    case a of
        Ok b ->
            succeed b

        Err b ->
            fail b



--


{-| -}
decodeTask : Decoder a -> Task String Decode.Value -> Task String a
decodeTask decoder a =
    a
        |> andThen
            (\v ->
                v
                    |> Decode.decodeValue decoder
                    |> Result.mapError Decode.errorToString
                    |> resultToTask
            )
