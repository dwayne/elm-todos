module Main exposing (main)


import Html exposing (..)
import Html.Attributes exposing (..)


main : Html msg
main =
  input
    [ type_ "text"
    , autofocus True
    , placeholder "What needs to be done?"
    ]
    []
