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
  { description : String
  , entries : List String
  }

model : Model
model =
  { description = ""
  , entries = []
  }

-- UPDATE

type Msg
  = SetDescription String
  | AddEntry

update : Msg -> Model -> Model
update msg model =
  case msg of
    SetDescription description ->
      { model | description = description }

    AddEntry ->
      let
        cleanDescription =
          String.trim model.description
      in
        if String.isEmpty cleanDescription then
          model
        else
          { model
          | description = ""
          , entries = model.entries ++ [ cleanDescription ]
          }

-- VIEW

view : Model -> Html Msg
view { description, entries } =
  div []
    [ Html.form [ Events.onSubmit AddEntry ]
        [ input
            [ type_ "text"
            , autofocus True
            , placeholder "What needs to be done?"
            , value description
            , Events.onInput SetDescription
            ]
            []
        ]
    , ul [] (List.map (\description -> li [] [ text description ]) entries)
    ]
