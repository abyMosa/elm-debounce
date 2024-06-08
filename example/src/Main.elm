module Main exposing (main)

import Browser
import Debounce exposing (Debounce)
import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)


type alias Model =
    { count : Int
    , debounce : Debounce Msg
    }


type Msg
    = Increment
    | Decrement
    | DebounceMsg (Debounce.Msg Msg)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { count = 0, debounce = Debounce.init 500 }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }
            , Cmd.none
            )

        Decrement ->
            ( { model | count = model.count - 1 }
            , Cmd.none
            )

        DebounceMsg debounceMsg ->
            Debounce.update DebounceMsg debounceMsg model.debounce
                |> Tuple.mapFirst (\debounce -> { model | debounce = debounce })


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Increment ] [ text "+" ]
        , button [ onClick (Debounce.event DebounceMsg Increment) ] [ text "Increment" ]
        , div [] [ text (String.fromInt model.count) ]
        , button [ onClick Decrement ] [ text "-" ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
