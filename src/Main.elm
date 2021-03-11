module Main exposing (main)


import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as E


main : Program () Model Msg
main =
  Browser.sandbox
    { init = init
    , update = update
    , view = view
    }


-- MODEL


type alias Model =
  { description : String
  }


init : Model
init =
  Model ""


-- UPDATE


type Msg
  = ChangedDescription String


update : Msg -> Model -> Model
update msg model =
  case msg of
    ChangedDescription description ->
      { model | description = description }


-- VIEW


view : Model -> Html Msg
view { description } =
  input
    [ type_ "text"
    , autofocus True
    , placeholder "What needs to be done?"
    , value description
    , E.onInput ChangedDescription
    ]
    []
