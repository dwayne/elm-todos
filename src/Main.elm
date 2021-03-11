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
  , entries : List Entry
  }


type alias Entry =
  { description : String
  , completed : Bool
  }


init : Model
init =
  Model "" []


-- UPDATE


type Msg
  = ChangedDescription String
  | SubmittedDescription


update : Msg -> Model -> Model
update msg model =
  case msg of
    ChangedDescription description ->
      { model | description = description }

    SubmittedDescription ->
      let
        cleanDescription =
          String.trim model.description
      in
      if String.isEmpty cleanDescription then
        model
      else
        { model
        | description = ""
        , entries = model.entries ++ [ createEntry cleanDescription ]
        }


createEntry : String -> Entry
createEntry description =
  Entry description False


-- VIEW


view : Model -> Html Msg
view { description, entries } =
  div []
    [ Html.form [ E.onSubmit SubmittedDescription ]
        [ input
            [ type_ "text"
            , autofocus True
            , placeholder "What needs to be done?"
            , value description
            , E.onInput ChangedDescription
            ]
            []
        ]
    , ul [] (List.map (\entry -> li [] [ viewEntry entry ]) entries)
    ]


viewEntry : Entry -> Html msg
viewEntry { description } =
  text description
