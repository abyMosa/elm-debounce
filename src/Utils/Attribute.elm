module Utils.Attribute exposing (alwaysPrevent, attributeIf)

import Html exposing (Attribute)
import Html.Attributes exposing (class)


{-| -}
alwaysPrevent : msg -> ( msg, Bool )
alwaysPrevent msg =
    ( msg, True )


{-| -}
emptyAttribute : Attribute msg
emptyAttribute =
    class ""


{-| -}
attributeIf : Bool -> Attribute msg -> Attribute msg
attributeIf condition attribute =
    if condition then
        attribute

    else
        emptyAttribute
