module Debounce exposing
    ( Debounce(..), DebounceMsg, init, update
    , push
    , event, composeEvent, on, alwaysPreventDefaultOn, alwatsStopPropagationOn, custom
    )

{-| The `Debounce` type keeps track of messages it's received in a
particular burst. Every message added to the list schedules a check some time
in the future; if the list hasn't changed in that time we emit the newest
message in the list and discard the rest.


# The Basics

@docs Debounce, DebounceMsg, init, update


# Usage

To use the Debounce module. First, you will need to define a `Debounce` in your model,
initialize it with `init` function, and `update` it in your update function.

Then the actual debounce functionality is provided either in your update function using
[`Debounce.push`](#push) or in your HTML using one of the Debounce [events'](#events)
functions.

The difference between the two is that the `push` function is used when you **DO** want to
capture some data from the event source as they occur, while `events` functions are used
when you **DO NOT** want to capture data from the event source as they occur.

**Example**: Suppose you want search an API in realtime as the user types,
or developing an autocomplete feature that gets results from an API as the user types. You
need the text input to be updated as the user types. However, Http request needs to be sent
to the API when the user stops typing.

[`Debounce.push`](#push) is perfect fit as it will allow you to capture and update the text
input as the user types, and then send the Http request when the user stops typing.

If you use [events](#events) in this case, you will not be able to capture the text input
as the user types.

**Example** : a pagination component that sends out a HTTP request on page change, we want
to prevent a sudden burst of requests being sent if the user clicks the "next page" button
multiple times.

In this case, one of the Debounce events such as `Debounce.event` would be a perfict fit
as opposed to `Debounce.push` as

  - It doesn't need any data comeing from the event source.

  - It applies the debouncing functionality right in HTML without cluttering up the `update`
    function unnecessarily.

```elm
button
    [ Debounce.event onClick NextPage model.debouncer ]
    [ Html.text ">>" ]
```


# Push

@docs push


# Events


## Debounce right at the source, in the HTML.

This is useful when you want to debounce events that are coming from the user, like clicks,
key presses, etc. It almost covers all the events that are available in Http.Events module.

This is useful when you **DO NOT** want to capture some data from the event source as they occur.

It produces an `Attribute msg` that can be used in the HTML.

Both `event` and `composeEvent` cover all elm events that are available in elm
[Html.Events](https://package.elm-lang.org/packages/elm/html/latest/Html-Events) module.

`on`, `alwaysPreventDefaultOn`, `alwatsStopPropagationOn`, and `custom` allow you create custom events with custom
decoders. This is useful when you want to debounce custom events that are not available in
the Html.Events module like `mousemove`, `scroll`, etc.

@docs event, composeEvent, on, alwaysPreventDefaultOn, alwatsStopPropagationOn, custom

-}

import Html exposing (Attribute)
import Html.Events
import Json.Decode as Decode exposing (Decoder)
import Utils.Attribute exposing (alwaysPrevent)
import Utils.Cmd exposing (emit, emitAfter)


{-| A type for the Debouncer that keeps track of messages it's received in a
particular burst. When that burst settles after the provided cooldown period,
the newest meesage gets emitted.

    -- define a debouncer in your component
    type alias Model =
        { inputText : String
        , debouncer : Debounce Msg
        }

-}
type Debounce msg
    = Debounce
        { cooldown : Int
        , queue : List msg
        , tagger : DebounceMsg msg -> msg
        }


{-| A type for messages internal to the Debounce.

    -- define a `Debounce.DebounceMsg Msg` type in your component
    type Msg
        = DebounceMsg (Debounce.DebounceMsg Msg)
        | ...

-}
type DebounceMsg msg
    = EmitIfSettled Int
    | Push msg


{-| You will need to provide a `tagger` function that will wrap the `DebounceMsg`
and a `cooldown` value that will determine how long the Debouncer will wait before
checking if the burst has settled.

    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { inputText = ""
          , debouncer = Debounce.init DebounceMsg 500
          }
        , Cmd.none
        )

-}
init : (DebounceMsg msg -> msg) -> Int -> Debounce msg
init tagger cooldown =
    Debounce { cooldown = cooldown, queue = [], tagger = tagger }


{-| The update function produces Cmds like any other update function. You will
need to use it for every Debouncer you have in an application in order for
the `Debounce` to handle its internal messages.

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            ...
            DebounceMsg debounceMsg ->
                Debounce.update debounceMsg model.debouncer
                    |> Tuple.mapFirst (\debouncer -> { model | debouncer = debouncer })

-}
update : DebounceMsg msg -> Debounce msg -> ( Debounce msg, Cmd msg )
update internalMsg ((Debounce { cooldown, queue, tagger }) as debounce) =
    case internalMsg of
        EmitIfSettled msgCount ->
            if List.length queue == msgCount then
                ( resetQueue debounce
                , List.head queue
                    |> Maybe.map emit
                    |> Maybe.withDefault Cmd.none
                )

            else
                ( debounce, Cmd.none )

        Push msg ->
            ( addToQueue msg debounce
            , emitAfter cooldown (tagger <| EmitIfSettled (List.length queue + 1))
            )


{-| Push a messages into the Debouncer. Every message added to the list schedules a check
some time in the future. If the list hasn't changed in that time, we emit the newest message
in the list and discard the rest.

This is useful when you **DO** want to capture some data from the event source as they occur.

    -- define a debouncer in your component
    type alias Model =
        { inputText : String
        , debouncer : Debounce Msg
        }

    -- define a `Debounce.DebounceMsg Msg` type in your component
    type Msg
        = UpdateInputText String
        | SendRequest String
        | DebounceMsg (Debounce.DebounceMsg Msg)


    -- init
    init : () -> ( Model, Cmd Msg )
    init _ =
        ( { inputText = ""
          , debouncer = Debounce.init DebounceMsg 500
          }
        , Cmd.none
        )

    -- update
    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            ...
            UpdateInputText text ->
                Debounce.push (SendRequest text) model.debouncer
                    |> Tuple.mapFirst
                        (\debouncer ->
                            { model
                                | debouncer = debouncer
                                , inputText = text
                            }
                        )

            SendRequest text ->
                ( model
                , Http.get
                    { ...
                    }
                )

            DebounceMsg debounceMsg ->
                Debounce.update debounceMsg model.debouncer
                    |> Tuple.mapFirst
                        (\debouncer ->
                            { model
                                | debouncer = debouncer
                            }
                        )



    -- view
    view : Model -> Html Msg
    view model =
        input
            [ type_ "text"
            , value model.inputText
            , onInput UpdateInputText
            ]
            []

-}
push : msg -> Debounce msg -> ( Debounce msg, Cmd msg )
push msg ((Debounce { cooldown, queue, tagger }) as debounce) =
    ( addToQueue msg debounce
    , emitAfter cooldown (tagger <| EmitIfSettled (List.length queue + 1))
    )


{-| `event` allows you to debounce any HTML event with `(msg -> Attribute msg)` definition
such as `onClick`, `onMouseDown`, etc.

    type alias Model =
        { debouncer : Debounce Msg
        , ...
        }

    type Msg
        = DoSomething
        | DebounceMsg (Debounce.DebounceMsg Msg)
        | ...

    init : Model
    init =
        { debouncer = Debounce.init DebounceMsg 500
        , ...
        }

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            DoSomething ->
                ( model
                , Http.get
                    { ...
                    }
                )

            DebounceMsg DebounceMsg ->
                Debounce.update DebounceMsg model.debouncer
                    |> Tuple.mapFirst (\debouncer -> { model | debouncer = debouncer })

    view : Model -> Html Msg
    view model =
        button
            [ Debounce.event onClick DoSomething model.debouncer ]
            [ Html.text "Click" ]

-}
event : (msg -> Attribute msg) -> msg -> Debounce msg -> Attribute msg
event htmlEvent msg debouncer =
    htmlEvent (toMsg debouncer msg)


{-| Debounce any event with `((a -> msg) -> Attribute msg)` definition

It composes event `(a -> msg) -> Attribute msg` with Msg `(a -> msg)`
to give you the final `Attribute msg` while applying the debounce functionality.

    -- Usage

    Input
        [ type "text"
        , Debounce.composeEvent onInput UpdateText model.debouncer
        ]
        []

-}
composeEvent : ((a -> msg) -> Attribute msg) -> (a -> msg) -> Debounce msg -> Attribute msg
composeEvent htmlEvent msg debouncer =
    htmlEvent (msg >> toMsg debouncer)


{-| Debounce custom events with custom decoders.
This is useful when you want to debounce custom events that are not available in the Html.Events module like `mousemove`.

    -- Eg: do something when the mouse moves stops

    mousemoveDecoder : (Int -> Int -> msg) -> Decode.Decoder msg
    mousemoveDecoder msg =
        Decode.map2 msg
            (Decode.field "clientX" Decode.int)
            (Decode.field "clientY" Decode.int)

    div
        [ Debounce.on "mousemove" (mousemoveDecoder GotPosition) model.debouncer ]
        []

-}
on : String -> Decoder msg -> Debounce msg -> Attribute msg
on eventName decoder debouncer =
    Decode.map (toMsg debouncer) decoder |> Html.Events.on eventName


{-| Similar to `on` it debounces custom events with custom decoders but it always preventDefault.
-}
alwaysPreventDefaultOn : String -> Decoder msg -> Debounce msg -> Attribute msg
alwaysPreventDefaultOn eventName decoder debouncer =
    Decode.map (toMsg debouncer >> alwaysPrevent) decoder
        |> Html.Events.preventDefaultOn eventName


{-| Similar to `on` it debounces custom events with custom decoders but it always stopPropagation.
-}
alwatsStopPropagationOn : String -> Decoder msg -> Debounce msg -> Attribute msg
alwatsStopPropagationOn eventName decoder debouncer =
    Decode.map (toMsg debouncer >> alwaysPrevent) decoder
        |> Html.Events.stopPropagationOn eventName


{-| Similar to `Html.Events.custom` but it allows you to debounce custom events with custom decoders while controlling stopPropagation and preventDefault.
-}
custom : String -> Decoder { message : msg, stopPropagation : Bool, preventDefault : Bool } -> Debounce msg -> Attribute msg
custom eventName decoder debouncer =
    decoder
        |> Decode.map
            (\{ message, stopPropagation, preventDefault } ->
                { message = toMsg debouncer message
                , stopPropagation = stopPropagation
                , preventDefault = preventDefault
                }
            )
        |> Html.Events.custom eventName



-- transformations


{-| -}
addToQueue : msg -> Debounce msg -> Debounce msg
addToQueue msg (Debounce ({ queue } as options)) =
    Debounce { options | queue = msg :: queue }


{-| -}
resetQueue : Debounce msg -> Debounce msg
resetQueue (Debounce options) =
    Debounce { options | queue = [] }


{-| -}
toMsg : Debounce msg -> msg -> msg
toMsg (Debounce { tagger }) msg =
    tagger (Push msg)
