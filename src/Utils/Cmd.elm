module Utils.Cmd exposing (emit, emitAfter)

import Process
import Task


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
