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
  { uid : Int
  , description : String
  , entries : List Entry
  }


type alias Entry =
  { uid : Int
  , description : String
  , completed : Bool
  }


init : Model
init =
  Model 0 "" []


-- UPDATE


type Msg
  = ChangedDescription String
  | SubmittedDescription
  | CheckedEntry Int Bool
  | ClickedRemoveButton Int


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
        | uid = model.uid + 1
        , description = ""
        , entries = model.entries ++ [ createEntry model.uid cleanDescription ]
        }

    CheckedEntry uid isChecked ->
      let
        updateEntry entry =
          if uid == entry.uid then
            { entry | completed = isChecked }
          else
            entry
      in
      { model | entries = List.map updateEntry model.entries }

    ClickedRemoveButton uid ->
      { model
      | entries = List.filter (\entry -> entry.uid /= uid) model.entries
      }


createEntry : Int -> String -> Entry
createEntry uid description =
  Entry uid description False


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


viewEntry : Entry -> Html Msg
viewEntry { uid, description, completed } =
  div [ class "hover-target" ]
    [ input
        [ type_ "checkbox"
        , checked completed
        , E.onCheck (CheckedEntry uid)
        ]
        []
    , span
        [ classList [ ("line-through", completed) ] ]
        [ text description ]
    , button
        [ type_ "button"
        , class "ml-1 visible-on-hover"
        , E.onClick (ClickedRemoveButton uid)
        ]
        [ text "x" ]
    ]
