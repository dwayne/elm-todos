module Todo exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)

main =
  input
    [ type_ "text"
    , autofocus True
    , placeholder "What needs to be done?"
    ]
    []
