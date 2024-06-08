module Debounce exposing (Debounce(..), Msg, event, init, push, update)

{-|

@docs Debounce, Msg, event, init, push, update

-}

import Process
import Task


{-| -}
type Debounce msg
    = Debounce Int (List msg)


{-| -}
type Msg msg
    = EmitIfSettled Int
    | Push msg


{-| -}
init : Int -> Debounce msg
init cooldown =
    Debounce cooldown []


{-| -}
event : (Msg msg -> msg) -> msg -> msg
event tagger msg =
    tagger (Push msg)


{-| -}
push : (Msg msg -> msg) -> msg -> Debounce msg -> ( Debounce msg, Cmd msg )
push tagger msg (Debounce cooldown queue) =
    ( Debounce cooldown (msg :: queue)
    , emitAfter cooldown (tagger <| EmitIfSettled (List.length queue + 1))
    )


{-|

    -- Usage
    update : (Msg msg -> msg) -> Msg msg -> Debounce msg -> ( Debounce msg, Cmd msg )

-}
update : (Msg msg -> msg) -> Msg msg -> Debounce msg -> ( Debounce msg, Cmd msg )
update tagger internalMsg ((Debounce cooldown queue) as debounce) =
    case internalMsg of
        EmitIfSettled msgCount ->
            if List.length queue == msgCount then
                ( Debounce cooldown []
                , List.head queue
                    |> Maybe.map emit
                    |> Maybe.withDefault Cmd.none
                )

            else
                ( debounce, Cmd.none )

        Push msg ->
            ( Debounce cooldown (msg :: queue)
            , emitAfter cooldown (tagger <| EmitIfSettled (List.length queue + 1))
            )


{-| -}
emitAfter : Int -> msg -> Cmd msg
emitAfter delay msg =
    toFloat delay
        |> Process.sleep
        |> Task.perform (always msg)


{-| -}
emit : msg -> Cmd msg
emit msg =
    Task.succeed msg
        |> Task.perform identity
