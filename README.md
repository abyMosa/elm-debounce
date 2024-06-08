# Elm Debounce

A simple debounce module that can be used as part of your update functions or directly from views as event msg.

## You can use it like so

#### **Option 1**: from your update fn

```elm
  let
    (debouncer, cmd) =
      Debounce.push DebounceMsg SendRequest model.debounce
  in
    ({model | debouncer = debouncer}, cmd)
```

#### **Option 2**: from your view as an event

```elm
  button
    [ onClick (Debounce.event DebounceMsg SendRequest) ]
    [ Html.text "Fetch user" ]
```

---

### Example for Option 1

say you have a controlled text input field that you want to send a api request with its value when the user stops typing.

you dont want to send an api request on every keystroke

#### 1\. Import the Debounce module

```elm
  import Debounce exposing (Debounce)
```

#### 2\. Add Debounce to your Model and Msg

```elm
  type alias Model =
      { inputText : String
      , debounce : Debounce Msg
      }

  type Msg
      = UpdateInputText String
      | SendRequest
      | DebounceMsg (Debounce.Msg Msg)
```

#### 3\. Initialise Debounce with a cooldown period in miliseconds as part of the init function

```elm
  init : () -> ( Model, Cmd Msg )
  init _ =
      ( { inputText = ""
        , debounce = Debounce.init 500
        }
      , Cmd.none
      )
```

#### 4\. In the update function

```elm
  update : Msg -> Model -> ( Model, Cmd Msg )
  update msg model =
      case msg of
          UpdateInputText string ->
            let
            ( debounce, cmd ) =
                -- here you would want to update the text field on every keystroke
                -- SendRequest Cmd gets pushed to the debouncer list of cmds
                -- when the user stops typing for 500 (the cooldown period) -> the last cmd gets fired, the rest will be ignored
                Debounce.push DebounceMsg SendRequest model.debounce
            in
            ( { model
                | debounce = debounce
                , inputText = string
              }
              , cmd
            )

          SendRequest ->
              let
                  _ =
                      Debug.log "Sending request" model.inputText
              in
              -- here you can fire the http request
              ( model, Cmd.none )

          DebounceMsg debounceMsg ->
              Debounce.update DebounceMsg debounceMsg model.debounce
                  |> Tuple.mapFirst (\debounce -> { model | debounce = debounce })
```

#### 5\. In the view

```elm
  input
    [ type_ "text"
    , value model.inputText
    , onInput UpdateInputText
    ] []
```


### Example for Option 2

say you want to send a http request on a btn click for any reason,

#### 1\. Import the Debounce module -> similar to option 1 step 1

#### 2\. Add Debounce to your Model and Msg -> similar to option 1 step 2

```elm
  type alias Model =
      { debounce : Debounce Msg
      }

  type Msg
      = SendRequest
      | DebounceMsg (Debounce.Msg Msg)
```

#### 3\. Initialise Debounce with a cooldown period in miliseconds as part of the init fn -> similar to option 1 step 3

#### 4\. In the update function
we will not use `Debounce.push` to add to the list of `Debounce cmds`, we will push to the cmds list directly from the view with an event in the next step, however, you would still have to create a case for DebounceMsg

```elm
  update : Msg -> Model -> ( Model, Cmd Msg )
  update msg model =
      case msg of
          SendRequest ->
              let
                  _ =
                      Debug.log "Sending request" model.inputText
              in
              -- here you can fire the http request
              ( model, Cmd.none )

          DebounceMsg debounceMsg ->
              Debounce.update DebounceMsg debounceMsg model.debounce
                  |> Tuple.mapFirst (\debounce -> { model | debounce = debounce })
```

#### 5\. In the view

```elm
  button
    [ onClick (Debounce.event DebounceMsg SendRequest) ]
    [ Html.text "Click me" ]
```

---
### `Debounce.push` vs `Debounce.event`
`Debounce.push` is useful when you want to update multiple things, only some of those updates you want to debounce

In our first example above, if we were to use `Debouce.event` rather than `Debounce.push` like so
```elm
  input
    [ type_ "text"
    , value model.inputText
    , onInput (UpdateInputText >> Debounce.event DebounceMsg)
    ] []
```
updating the text field value will then be debounced (which is not the desired behaviour), instead, we can pass `UpdateInputText` Msg as handler for `onInput`, and in the update function we can update the text input value and push `SendRequest` to the `Debounce` Cmd list

```elm
view model =
    input
    [ type_ "text"
    , value model.inputText
    , onInput UpdateInputText
    ] []

update msg model =
    case msg of
      UpdateInputText string ->
        let
        ( debounce, cmd ) =
            Debounce.push DebounceMsg SendRequest model.debounce
        in
        ( { model
            | debounce = debounce
            , inputText = string
          }
          , cmd
        )
```
