module Generated.Basics.Decode exposing (..)

import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder)
import Set exposing (Set)


{-| To decode char.
-}
char : Decoder Char
char =
    D.string
        |> D.andThen
            (\a ->
                case a |> String.toList of
                    b :: [] ->
                        D.succeed b

                    _ ->
                        D.fail "I was expecting exactly one char."
            )


{-| To decode set.
-}
set : Decoder comparable -> Decoder (Set comparable)
set a =
    D.map Set.fromList (D.list a)


{-| To decode dictionary.
-}
dict : k -> Decoder v -> Decoder (Dict String v)
dict _ a =
    D.dict a


{-| To maybe decode field.
-}
maybeField : String -> Decoder (Maybe a) -> Decoder (Maybe a)
maybeField name a =
    D.oneOf
        [ D.map Just (D.field name D.value)
        , D.succeed Nothing
        ]
        |> D.andThen
            (\v ->
                case v of
                    Just _ ->
                        D.field name a

                    Nothing ->
                        D.succeed Nothing
            )


{-| To decode result.
-}
result : Decoder e -> Decoder v -> Decoder (Result e v)
result errorDecoder valueDecoder =
    D.index 0 D.string
        |> D.andThen
            (\tag ->
                case tag of
                    "Ok" ->
                        D.map Ok (D.index 1 valueDecoder)

                    "Err" ->
                        D.map Err (D.index 1 errorDecoder)

                    _ ->
                        D.fail ("I can't decode Result, unknown tag \"" ++ tag ++ "\".")
            )



--


duo : Decoder a -> Decoder b -> Decoder ( a, b )
duo =
    D.map2 Tuple.pair


trio : Decoder a -> Decoder b -> Decoder c -> Decoder ( a, b, c )
trio =
    D.map3 (\a b c -> ( a, b, c ))


map9 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder value
map9 fn a b =
    D.map8 (\( a_, b_ ) -> fn a_ b_)
        (duo a b)


map10 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder value
map10 fn a b c =
    D.map8 (\( a_, b_, c_ ) -> fn a_ b_ c_)
        (trio a b c)


map11 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder k
    -> Decoder value
map11 fn a b c d e =
    D.map8 (\( a_, b_, c_ ) ( d_, e_ ) -> fn a_ b_ c_ d_ e_)
        (trio a b c)
        (duo d e)


map12 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder k
    -> Decoder l
    -> Decoder value
map12 fn a b c d e f =
    D.map8 (\( a_, b_, c_ ) ( d_, e_, f_ ) -> fn a_ b_ c_ d_ e_ f_)
        (trio a b c)
        (trio d e f)


map13 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder k
    -> Decoder l
    -> Decoder m
    -> Decoder value
map13 fn a b c d e f g h =
    D.map8 (\( a_, b_, c_ ) ( d_, e_, f_ ) ( g_, h_ ) -> fn a_ b_ c_ d_ e_ f_ g_ h_)
        (trio a b c)
        (trio d e f)
        (duo g h)


map14 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder k
    -> Decoder l
    -> Decoder m
    -> Decoder n
    -> Decoder value
map14 fn a b c d e f g h i =
    D.map8 (\( a_, b_, c_ ) ( d_, e_, f_ ) ( g_, h_, i_ ) -> fn a_ b_ c_ d_ e_ f_ g_ h_ i_)
        (trio a b c)
        (trio d e f)
        (trio g h i)


map15 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> o -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder k
    -> Decoder l
    -> Decoder m
    -> Decoder n
    -> Decoder o
    -> Decoder value
map15 fn a b c d e f g h i j k =
    D.map8 (\( a_, b_, c_ ) ( d_, e_, f_ ) ( g_, h_, i_ ) ( j_, k_ ) -> fn a_ b_ c_ d_ e_ f_ g_ h_ i_ j_ k_)
        (trio a b c)
        (trio d e f)
        (trio g h i)
        (duo j k)


map16 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> o -> p -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder k
    -> Decoder l
    -> Decoder m
    -> Decoder n
    -> Decoder o
    -> Decoder p
    -> Decoder value
map16 fn a b c d e f g h i j k l =
    D.map8 (\( a_, b_, c_ ) ( d_, e_, f_ ) ( g_, h_, i_ ) ( j_, k_, l_ ) -> fn a_ b_ c_ d_ e_ f_ g_ h_ i_ j_ k_ l_)
        (trio a b c)
        (trio d e f)
        (trio g h i)
        (trio j k l)


map17 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> o -> p -> q -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder k
    -> Decoder l
    -> Decoder m
    -> Decoder n
    -> Decoder o
    -> Decoder p
    -> Decoder q
    -> Decoder value
map17 fn a b c d e f g h i j k l m n =
    D.map8 (\( a_, b_, c_ ) ( d_, e_, f_ ) ( g_, h_, i_ ) ( j_, k_, l_ ) ( m_, n_ ) -> fn a_ b_ c_ d_ e_ f_ g_ h_ i_ j_ k_ l_ m_ n_)
        (trio a b c)
        (trio d e f)
        (trio g h i)
        (trio j k l)
        (duo m n)


map18 :
    (a -> b -> c -> d -> e -> f -> g -> h -> i -> j -> k -> l -> m -> n -> o -> p -> q -> r -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder d
    -> Decoder e
    -> Decoder f
    -> Decoder g
    -> Decoder h
    -> Decoder i
    -> Decoder j
    -> Decoder k
    -> Decoder l
    -> Decoder m
    -> Decoder n
    -> Decoder o
    -> Decoder p
    -> Decoder q
    -> Decoder r
    -> Decoder value
map18 fn a b c d e f g h i j k l m n o =
    D.map8 (\( a_, b_, c_ ) ( d_, e_, f_ ) ( g_, h_, i_ ) ( j_, k_, l_ ) ( m_, n_, o_ ) -> fn a_ b_ c_ d_ e_ f_ g_ h_ i_ j_ k_ l_ m_ n_ o_)
        (trio a b c)
        (trio d e f)
        (trio g h i)
        (trio j k l)
        (trio m n o)
