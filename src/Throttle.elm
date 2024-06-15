module Throttle exposing
    ( Throttle(..), ThrottleMsg, init, update
    , push
    , event, composeEvent, on, alwaysPreventDefaultOn, alwaysStopPropagationOn, custom
    )

{-| A Throttler limits messages by only allowing messages to come in as fast
as a fixed interval allows. When receive a burst of messages, the first one
will pass through the emitter and then all messages are ignored for a period of
time, then the next message will pass through and so on.

When events are throttled using one of the Throttle events' functions, the module
doesnt just send a **`NoOp`** message, instead it blocks any messages by deregistering
the event listener. This is to avoid unnecessary messages being sent to the update
function and the elm runtime.


# The Basics

@docs Throttle, ThrottleMsg, init, update


# Usage

To use the Throttle module. First, you will need to define a `Throttle` in your model,
initialize it with `init` function, and `update` it in your update function.

Then the actual throttle functionality is provided either in your update function using
[`Throttle.push`](#push) or in your HTML using one of the Throttle [events'](#events)
functions.

The difference between the two is that the `push` function is used when you **DO** want to
capture some data from the event source as they occur, while `events` functions are used
when you **DO NOT** want to capture data from the event source as they occur.

**Example**: Suppose you want log information about the user's mouse position, you need
the logging to be throttled. You also need to keep track of the mouse position for some
animation functionality.

[`Throttle.push`](#push) is perfect fit as it will throttle the log message but still
keep track of the mouse position data as they occur.

If you use [events](#events) like the following, the emitted Msg `GotPosition` will be
throttled and you will loose the mouse position data as they occur.

    Throttle.on "mousemove" (decoder GotPosition) model.throttler


# Push


## Throttle from the update function.

This is useful when you **DO** want to capture some data from the event source as they occur.

@docs push


# Events


## Throttle right at the source, in the HTML.

This is useful when you want to throttle events that are coming from the user,
like clicks, key presses, etc. It almost covers all the events that are available
in Http.Events module.

It produces an `Attribute msg` that can be used in the HTML.

This is useful when you **DO NOT** want to capture some data from the event source as they occur.

Both `event` and `composeEvent` cover all elm events that are available in elm
[Html.Events](https://package.elm-lang.org/packages/elm/html/latest/Html-Events) module.

`on`, `alwaysPreventDefaultOn`, `alwaysStopPropagationOn`, and `custom` allow you create custom events
with custom decoders. This is useful when you want to throttle custom events that
are not available in the Html.Events module like `mousemove`, `scroll`, etc.

@docs event, composeEvent, on, alwaysPreventDefaultOn, alwaysStopPropagationOn, custom

-}

import Html exposing (Attribute)
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Utils.Attribute exposing (alwaysPrevent, attributeIf)
import Utils.Cmd exposing (emit, emitAfter)


{-| -}
type Status
    = Open
    | Closed


{-| A type for `Throttler` that limits messages by only allowing messages to come in
as fast as a fixed interval allows. When receive a burst of messages, the first one
will pass through the emitter and then all messages are ignored for a period of
time, then the next message will pass through and so on.

    -- define Throttler in your component
    type alias Model =
        { throttler : Throttle Msg
        , ...
        }

-}
type Throttle msg
    = Throttle
        { interval : Int
        , status : Status
        , tagger : ThrottleMsg msg -> msg
        }


{-| A type for messages internal to the Debounce.

    -- define (Throttle.ThrottleMsg Msg) type in your component
    type Msg
        = DoSomething
        | ThrottleMsg (Throttle.ThrottleMsg Msg)
        | ...

-}
type ThrottleMsg msg
    = ReOpen
    | Emit msg


{-| You will need to provide a `tagger` function that will wrap the `ThrottleMsg`
and an `interval` value that will pass before consecutive messages can be emitted.

    -- initialize your Throttle
    -- passing in the tagger function and the interval
    init : Model
    init =
        { throttler = Throttle.init ThrottleMsg 5000
        , ...
        }

-}
init : (ThrottleMsg msg -> msg) -> Int -> Throttle msg
init tagger interval =
    Throttle { interval = interval, tagger = tagger, status = Open }


{-| The update function produces Cmds like any other update function. You will
need to use it for every Throttler you have in an application in order for
the `Throttle` to handle its internal messages.

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            DoSomething ->
                ( model, Cmd.none )

            ThrottleMsg throttleMsg ->
                Throttle.update throttleMsg model.throttler
                    |> Tuple.mapFirst (\throttler -> { model | throttler = throttler })

-}
update : ThrottleMsg msg -> Throttle msg -> ( Throttle msg, Cmd msg )
update internalMsg ((Throttle { status, interval, tagger }) as throttle) =
    case internalMsg of
        ReOpen ->
            ( withStatus Open throttle, Cmd.none )

        Emit msg ->
            case status of
                Open ->
                    ( withStatus Closed throttle
                    , Cmd.batch
                        [ emit msg
                        , emitAfter interval (ReOpen |> tagger)
                        ]
                    )

                Closed ->
                    ( throttle, Cmd.none )


{-| Push a messages into the Throttle. This is useful when you **DO** want to capture some
data from the event source as they occur. When the Throttle receives a burst of messages,
the first one will pass through the emitter and then all messages are ignored for a period of time,
then the next message will pass through and so on.

    type alias Position =
        { x : Int
        , y : Int
        }

    -- define your model
    type alias Model =
        { throttler : Throttle Msg
        , position : Position
        , ...
        }

    -- define your Msg type
    type Msg
        = GotPosition x y
        | LogMsg x y
        | ThrottleMsg (Throttle.ThrottleMsg Msg)
        | ...


    -- initialize your Model
    init : Model
    init =
        { throttler = Throttle.init ThrottleMsg 5000
        , Position 0 0
        , ...
        }


    -- update
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            GotPosition x y ->
                Throttle.push (LogMsg x y) model.throttler
                    |> Tuple.mapFirst
                        (\throttler ->
                            { model
                                | throttler = throttler
                                , position = { x = x, y = y }
                            }
                        )

            LogMsg x y ->
                ( model
                , Http.post
                    { ...
                    }
                )

            ThrottleMsg throttleMsg ->
                Throttle.update throttleMsg model.throttler
                    |> Tuple.mapFirst (\throttler -> { model | throttler = throttler })


    -- view
    view : Model -> Html Msg
    view model =
        div
            [ on "mousemove" (mouseMoveDecoder GotPosition) ]
            [...
            ]

    -- mousemove decoder
    mouseMoveDecoder GotPosition =
        Decode.map2 GotPosition
            (Decode.field "clientX" Decode.int)
            (Decode.field "clientY" Decode.int)

Here the `GotPosition` message will Not be throttled and it will capture the mouse position as the mouse moves,
however the `LogMsg` will be throttled.

-}
push : msg -> Throttle msg -> ( Throttle msg, Cmd msg )
push msg ((Throttle { status, interval, tagger }) as throttle) =
    case status of
        Open ->
            ( throttle |> withStatus Closed
            , Cmd.batch
                [ emit msg
                , emitAfter interval (ReOpen |> tagger)
                ]
            )

        Closed ->
            ( throttle, Cmd.none )



-- Events


{-| `event` allows you to throttle any event with `(msg -> Attribute msg)` definition
such as `onClick`, `onMouseDown`, etc.

    type alias Model =
        { throttler : Throttle Msg
        , ...
        }

    type Msg
        = DoSomething
        | ThrottleMsg (Throttle.ThrottleMsg Msg)
        | ...

    init : Model
    init =
        { throttler = Throttle.init ThrottleMsg 1000
        , ...
        }

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            DoSomething ->
                ( model, Cmd.none )

            ThrottleMsg throttleMsg ->
                Throttle.update throttleMsg model.throttler
                    |> Tuple.mapFirst (\throttler -> { model | throttler = throttler })

    view : Model -> Html Msg
    view model =
        button
            [ Throttle.event onClick DoSomething model.throttler ]
            [ Html.text "Click" ]

-}
event : (msg -> Attribute msg) -> msg -> Throttle msg -> Attribute msg
event htmlEvent msg (Throttle { tagger, status }) =
    Emit msg |> tagger |> htmlEvent |> attributeIf (status == Open)


{-| Throttle any event with `((a -> msg) -> Attribute msg)` definition

It composes event `(a -> msg) -> Attribute msg` with Msg `(a -> msg)`
to give you the final `Attribute msg` while applying the throttle.

    -- Usage

    Input
        [ type "text"
        , Throttle.composeEvent onInput UpdateText model.throttler
        ]
        []

-}
composeEvent : ((a -> msg) -> Attribute msg) -> (a -> msg) -> Throttle msg -> Attribute msg
composeEvent htmlEvent msg (Throttle { tagger, status }) =
    msg >> Emit >> tagger |> htmlEvent |> attributeIf (status == Open)


{-| Throttle custom events with custom decoders. This is useful when you want to
throttle custom events that are not available in the Html.Events module like `mousemove`.

    mousemoveDecoder : (Int -> Int -> msg) -> Decode.Decoder msg
    mousemoveDecoder msg =
        Decode.map2 msg
            (Decode.field "clientX" Decode.int)
            (Decode.field "clientY" Decode.int)

    div
        [ Throttle.on "mousemove" (mousemoveDecoder GotPosition) model.throttler ]
        []

-}
on : String -> Decoder msg -> Throttle msg -> Attribute msg
on eventName decoder (Throttle { tagger, status }) =
    Decode.map (Emit >> tagger) decoder |> Html.Events.on eventName |> attributeIf (status == Open)


{-| Similar to `on` it throttle custom events with custom decoders but it always preventDefault.
-}
alwaysPreventDefaultOn : String -> Decoder msg -> Throttle msg -> Attribute msg
alwaysPreventDefaultOn eventName decoder (Throttle { tagger, status }) =
    Decode.map (Emit >> tagger >> alwaysPrevent) decoder
        |> Html.Events.preventDefaultOn eventName
        |> attributeIf (status == Open)


{-| Similar to `on` it throttle custom events with custom decoders but it always stopPropagation.
-}
alwaysStopPropagationOn : String -> Decoder msg -> Throttle msg -> Attribute msg
alwaysStopPropagationOn eventName decoder (Throttle { tagger, status }) =
    Decode.map (Emit >> tagger >> alwaysPrevent) decoder
        |> Html.Events.stopPropagationOn eventName
        |> attributeIf (status == Open)


{-| Similar to `Html.Events.custom` but it allows you to throttle custom events with custom decoders while controlling stopPropagation and preventDefault.
-}
custom : String -> Decoder { message : msg, stopPropagation : Bool, preventDefault : Bool } -> Throttle msg -> Attribute msg
custom eventName decoder (Throttle { tagger }) =
    decoder
        |> Decode.map
            (\{ message, stopPropagation, preventDefault } ->
                { message = Emit message |> tagger
                , stopPropagation = stopPropagation
                , preventDefault = preventDefault
                }
            )
        |> Html.Events.custom eventName



-- transformations


{-| -}
withStatus : Status -> Throttle msg -> Throttle msg
withStatus status (Throttle config) =
    Throttle { config | status = status }
