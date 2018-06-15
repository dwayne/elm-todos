module Todo exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events

main : Program Never Model Msg
main =
  Html.beginnerProgram
    { model = model
    , update = update
    , view = view
    }

-- MODEL

type alias Model =
  { description : String }

model : Model
model =
  { description = "" }

-- UPDATE

type Msg
  = SetDescription String

update : Msg -> Model -> Model
update msg model =
  case msg of
    SetDescription description ->
      { model | description = description }

-- VIEW

view : Model -> Html Msg
view { description } =
  input
    [ type_ "text"
    , autofocus True
    , placeholder "What needs to be done?"
    , value description
    , Events.onInput SetDescription
    ]
    []
