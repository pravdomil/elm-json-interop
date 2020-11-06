module Utils.TaskUtils exposing (..)

{-| <https://github.com/avh4/elm-format/issues/568#issuecomment-554753735>
-}

import Json.Decode as Decode exposing (Decoder)
import Task exposing (..)


{-| -}
taskAndThen2 :
    (a -> b -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x result
taskAndThen2 fn a b =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    fn
                        a_
                        b_
                )
                b
        )
        a


{-| -}
taskAndThen3 :
    (a -> b -> c -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x c
    -> Task x result
taskAndThen3 fn a b c =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    andThen
                        (\c_ ->
                            fn
                                a_
                                b_
                                c_
                        )
                        c
                )
                b
        )
        a


{-| -}
taskAndThen4 :
    (a -> b -> c -> d -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x c
    -> Task x d
    -> Task x result
taskAndThen4 fn a b c d =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    andThen
                        (\c_ ->
                            andThen
                                (\d_ ->
                                    fn
                                        a_
                                        b_
                                        c_
                                        d_
                                )
                                d
                        )
                        c
                )
                b
        )
        a


{-| -}
taskAndThen5 :
    (a -> b -> c -> d -> e -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x c
    -> Task x d
    -> Task x e
    -> Task x result
taskAndThen5 fn a b c d e =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    andThen
                        (\c_ ->
                            andThen
                                (\d_ ->
                                    andThen
                                        (\e_ ->
                                            fn
                                                a_
                                                b_
                                                c_
                                                d_
                                                e_
                                        )
                                        e
                                )
                                d
                        )
                        c
                )
                b
        )
        a


{-| -}
taskAndThen6 :
    (a -> b -> c -> d -> e -> f -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x c
    -> Task x d
    -> Task x e
    -> Task x f
    -> Task x result
taskAndThen6 fn a b c d e f =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    andThen
                        (\c_ ->
                            andThen
                                (\d_ ->
                                    andThen
                                        (\e_ ->
                                            andThen
                                                (\f_ ->
                                                    fn
                                                        a_
                                                        b_
                                                        c_
                                                        d_
                                                        e_
                                                        f_
                                                )
                                                f
                                        )
                                        e
                                )
                                d
                        )
                        c
                )
                b
        )
        a


{-| -}
taskAndThen7 :
    (a -> b -> c -> d -> e -> f -> g -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x c
    -> Task x d
    -> Task x e
    -> Task x f
    -> Task x g
    -> Task x result
taskAndThen7 fn a b c d e f g =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    andThen
                        (\c_ ->
                            andThen
                                (\d_ ->
                                    andThen
                                        (\e_ ->
                                            andThen
                                                (\f_ ->
                                                    andThen
                                                        (\g_ ->
                                                            fn
                                                                a_
                                                                b_
                                                                c_
                                                                d_
                                                                e_
                                                                f_
                                                                g_
                                                        )
                                                        g
                                                )
                                                f
                                        )
                                        e
                                )
                                d
                        )
                        c
                )
                b
        )
        a


{-| -}
taskAndThen8 :
    (a -> b -> c -> d -> e -> f -> g -> h -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x c
    -> Task x d
    -> Task x e
    -> Task x f
    -> Task x g
    -> Task x h
    -> Task x result
taskAndThen8 fn a b c d e f g h =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    andThen
                        (\c_ ->
                            andThen
                                (\d_ ->
                                    andThen
                                        (\e_ ->
                                            andThen
                                                (\f_ ->
                                                    andThen
                                                        (\g_ ->
                                                            andThen
                                                                (\h_ ->
                                                                    fn
                                                                        a_
                                                                        b_
                                                                        c_
                                                                        d_
                                                                        e_
                                                                        f_
                                                                        g_
                                                                        h_
                                                                )
                                                                h
                                                        )
                                                        g
                                                )
                                                f
                                        )
                                        e
                                )
                                d
                        )
                        c
                )
                b
        )
        a


{-| -}
taskAndThen9 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x c
    -> Task x d
    -> Task x e
    -> Task x f
    -> Task x g
    -> Task x h
    -> Task x i
    -> Task x result
taskAndThen9 fn a b c d e f g h i =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    andThen
                        (\c_ ->
                            andThen
                                (\d_ ->
                                    andThen
                                        (\e_ ->
                                            andThen
                                                (\f_ ->
                                                    andThen
                                                        (\g_ ->
                                                            andThen
                                                                (\h_ ->
                                                                    andThen
                                                                        (\i_ ->
                                                                            fn
                                                                                a_
                                                                                b_
                                                                                c_
                                                                                d_
                                                                                e_
                                                                                f_
                                                                                g_
                                                                                h_
                                                                                i_
                                                                        )
                                                                        i
                                                                )
                                                                h
                                                        )
                                                        g
                                                )
                                                f
                                        )
                                        e
                                )
                                d
                        )
                        c
                )
                b
        )
        a


{-| -}
taskAndThen10 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> Task x result)
    -> Task x a
    -> Task x b
    -> Task x c
    -> Task x d
    -> Task x e
    -> Task x f
    -> Task x g
    -> Task x h
    -> Task x i
    -> Task x j
    -> Task x result
taskAndThen10 fn a b c d e f g h i j =
    andThen
        (\a_ ->
            andThen
                (\b_ ->
                    andThen
                        (\c_ ->
                            andThen
                                (\d_ ->
                                    andThen
                                        (\e_ ->
                                            andThen
                                                (\f_ ->
                                                    andThen
                                                        (\g_ ->
                                                            andThen
                                                                (\h_ ->
                                                                    andThen
                                                                        (\i_ ->
                                                                            andThen
                                                                                (\j_ ->
                                                                                    fn
                                                                                        a_
                                                                                        b_
                                                                                        c_
                                                                                        d_
                                                                                        e_
                                                                                        f_
                                                                                        g_
                                                                                        h_
                                                                                        i_
                                                                                        j_
                                                                                )
                                                                                j
                                                                        )
                                                                        i
                                                                )
                                                                h
                                                        )
                                                        g
                                                )
                                                f
                                        )
                                        e
                                )
                                d
                        )
                        c
                )
                b
        )
        a



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
