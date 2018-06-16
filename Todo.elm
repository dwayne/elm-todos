module Todo exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Html.Keyed as Keyed

main : Program Never Model Msg
main =
  Html.beginnerProgram
    { model = model
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

type Visibility
  = All
  | Active
  | Completed

type alias Entry =
  { uid : Int
  , description : String
  , completed : Bool
  }

model : Model
model =
  { uid = 0
  , description = ""
  , visible = All
  , entries = []
  }

-- UPDATE

type Msg
  = SetDescription String
  | AddEntry
  | RemoveEntry Int
  | ToggleEntry Int Bool
  | RemoveCompletedEntries
  | ToggleEntries Bool

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
          | uid = model.uid + 1
          , description = ""
          , entries = model.entries ++ [ createEntry model.uid cleanDescription ]
          }

    RemoveEntry uid ->
      { model | entries = List.filter (\entry -> entry.uid /= uid) model.entries }

    ToggleEntry uid completed ->
      let
        updateEntry entry =
          if entry.uid == uid then
            { entry | completed = completed }
          else
            entry
      in
        { model | entries = List.map updateEntry model.entries }

    RemoveCompletedEntries ->
      { model | entries = List.filter (not << .completed) model.entries }

    ToggleEntries completed ->
      let
        updateEntry entry =
          { entry | completed = completed }
      in
        { model | entries = List.map updateEntry model.entries }

createEntry : Int -> String -> Entry
createEntry uid description =
  { uid = uid, description = description, completed = False }

-- VIEW

view : Model -> Html Msg
view { description, visible, entries } =
  div []
    [ viewPrompt description
    , viewBody visible entries
    ]

viewPrompt : String -> Html Msg
viewPrompt description =
  Html.form [ Events.onSubmit AddEntry ]
    [ input
        [ type_ "text"
        , autofocus True
        , placeholder "What needs to be done?"
        , value description
        , Events.onInput SetDescription
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
             , Events.onCheck ToggleEntries
             ]
             []
          , text "Mark all as completed"
          ]
      , Keyed.ul []
          <| List.map
              (\entry -> (toString entry.uid, li [] [ viewEntry entry ]))
              (keep visible entries)
      , viewNumIncompleteEntries entries
      , button
          [ type_ "button"
          , Events.onClick RemoveCompletedEntries
          ]
          [ text "Clear completed" ]
      ]

viewEntry : Entry -> Html Msg
viewEntry { uid, description, completed } =
  div [ class "hover-target" ]
    [ input
        [ type_ "checkbox"
        , checked completed
        , Events.onCheck (ToggleEntry uid)
        ]
        []
    , span
        [ classList [ ("line-through", completed) ] ]
        [ text description ]
    , button
        [ type_ "button"
        , class "ml-1 visible-on-hover"
        , Events.onClick (RemoveEntry uid)
        ]
        [ text "x" ]
    ]

viewNumIncompleteEntries : List Entry -> Html msg
viewNumIncompleteEntries entries =
  let
    n =
      entries
        |> List.filter (not << .completed)
        |> List.length
  in
    div [] [ text <| toString n ++ " " ++ pluralize n "task" "tasks" ++ " left" ]

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
