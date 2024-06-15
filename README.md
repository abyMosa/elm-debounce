# Elm Debounce

A simple debounce and throttle module that can be used in your update function or
directly in HTML as an event.

The `Debounce` type keeps track of messages it's received in a
particular burst. Every message added to the list schedules a check some time
in the future; if the list hasn't changed in that time we emit the newest
message in the list and discard the rest.

The `Throttle` type limits messages by only allowing messages to come in as fast
as a fixed interval allows. When receive a burst of messages, the first one
will pass through the emitter and then all messages are ignored for a period of
time, then the next message will pass through and so on.

You can debounce or throttle from the update function using `Debounce.push`
or `Throttle.push` if you need to capture data from the event source as they occur.

You can debounce or throttle from HTML using one of the events' functions if you
**DONT** need to capture data from event source as they occur.

Events' functions produce `Attribute msg`

Events' functions `event` and `composeEvent` cover all elm events that are
available in [Html.Events](https://package.elm-lang.org/packages/elm/html/latest/Html-Events) module.

Events' functions `on`, `preventDefaultOn`, `stopPropagationOn` and `custom` allow
you create custom events with custom decoders. This is useful when you want to
debounce or throttle custom events that are not available in the Html.Events module
like `mousemove`, `scroll`, etc.



This package is influenced by two other packages in elm catalog with the following differences:
- It provides Events that cover all elm events that are available in
  [Html.Events](https://package.elm-lang.org/packages/elm/html/latest/Html-Events) module.
- It allows you debounce or throttle custom events with functions like `on`, `preventDefaultOn`, `stopPropagationOn` and `custom`.
- All Events' functions produces `Html.Attribute msg`
- When events are throttled using one of the Throttle events' functions, the module
doesnt just send a **`NoOp`** message, instead it blocks any messages by deregistering
the event listener. This is to avoid unnecessary messages being sent to the update
function and the elm runtime.
