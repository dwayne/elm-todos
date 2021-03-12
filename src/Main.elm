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
  , visible : Visibility
  , entries : List Entry
  }


type alias Entry =
  { uid : Int
  , description : String
  , completed : Bool
  }


type Visibility
  = All
  | Active
  | Completed


init : Model
init =
  Model 0 "" All []


-- UPDATE


type Msg
  = ChangedDescription String
  | SubmittedDescription
  | CheckedEntry Int Bool
  | ClickedRemoveButton Int
  | CheckedMarkAllCompleted Bool
  | ClickedRemoveCompletedEntriesButton


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

    CheckedMarkAllCompleted isChecked ->
      let
        updateEntry entry =
          { entry | completed = isChecked }
      in
      { model | entries = List.map updateEntry model.entries }

    ClickedRemoveCompletedEntriesButton ->
      { model | entries = List.filter (not << .completed) model.entries }


createEntry : Int -> String -> Entry
createEntry uid description =
  Entry uid description False


-- VIEW


view : Model -> Html Msg
view { description, visible, entries } =
  div []
    [ viewPrompt description
    , viewBody visible entries
    ]


viewPrompt : String -> Html Msg
viewPrompt description =
  Html.form [ E.onSubmit SubmittedDescription ]
    [ input
        [ type_ "text"
        , autofocus True
        , placeholder "What needs to be done?"
        , value description
        , E.onInput ChangedDescription
        ]
        []
    ]


viewBody : Visibility -> List Entry -> Html Msg
viewBody visible entries =
  if List.isEmpty entries then
    text ""
  else
    div []
      [ label []
          [ input
              [ type_ "checkbox"
              , checked (List.all .completed entries)
              , E.onCheck CheckedMarkAllCompleted
              ]
              []
          , text "Mark all as completed"
          ]
      , ul [] <|
          List.map (\entry -> li [] [ viewEntry entry ]) (keep visible entries)
      , viewStatus entries
      , button
          [ type_ "button"
          , E.onClick ClickedRemoveCompletedEntriesButton
          ]
          [ text "Clear completed" ]
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


viewStatus : List Entry -> Html msg
viewStatus entries =
  let
    n =
      entries
        |> List.filter (not << .completed)
        |> List.length
  in
  div []
    [ text <| String.fromInt n ++ " " ++ pluralize n "task" "tasks" ++ " left" ]


-- HELPERS


keep : Visibility -> List Entry -> List Entry
keep visible entries =
  case visible of
    All ->
      entries

    Active ->
      List.filter (not << .completed) entries

    Completed ->
      List.filter .completed entries


pluralize : Int -> String -> String -> String
pluralize n singular plural =
  if n == 1 then
    singular
  else
    plural
