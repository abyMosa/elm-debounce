module Main exposing (main)

import Browser
import Debounce exposing (Debounce)
import Html exposing (Html, button, div, input)
import Html.Attributes exposing (placeholder, type_, value)
import Html.Events exposing (onClick, onInput)


type alias Model =
    { inputText : String
    , debounce : Debounce Msg
    }


type Msg
    = UpdateInputText String
    | FetchUser
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
    ( { inputText = "", debounce = Debounce.init 500 }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateInputText string ->
            -- Debounce.push DebounceMsg FetchUser model.debounce
            --     |> Tuple.mapFirst (\debounce -> { model | debounce = debounce, inputText = string })
            let
                ( debounce, cmd ) =
                    Debounce.push DebounceMsg FetchUser model.debounce
            in
            ( { model | debounce = debounce, inputText = string }, cmd )

        FetchUser ->
            let
                _ =
                    Debug.log "Fetching user" model.inputText
            in
            ( model, Cmd.none )

        DebounceMsg debounceMsg ->
            Debounce.update DebounceMsg debounceMsg model.debounce
                |> Tuple.mapFirst (\debounce -> { model | debounce = debounce })


view : Model -> Html Msg
view model =
    div []
        [ input [ type_ "text", value model.inputText, placeholder "Enter a Github username", onInput UpdateInputText ] []

        -- , button [ onClick (Debounce.event DebounceMsg FetchUser) ] [ Html.text "Fetch user" ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
