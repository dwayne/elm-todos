module Todo exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Html.Keyed as Keyed
import Navigation

main : Program Never Model Msg
main =
  Navigation.program NewLocation
    { init = init
    , update = update
    , view = view
    , subscriptions = always Sub.none
    }

-- MODEL

type alias Model =
  { uid : Int
  , description : String
  , mode : Mode
  , visible : Visibility
  , entries : List Entry
  }

type Mode
  = Normal
  | Edit Int String

type Visibility
  = All
  | Active
  | Completed

type alias Entry =
  { uid : Int
  , description : String
  , completed : Bool
  }

init : Navigation.Location -> (Model, Cmd Msg)
init location =
  { uid = 0
  , description = ""
  , mode = Normal
  , visible = toVisibility location
  , entries = []
  } ! []

-- UPDATE

type Msg
  = NewLocation Navigation.Location
  | SetDescription String
  | AddEntry
  | RemoveEntry Int
  | ToggleEntry Int Bool
  | EditEntry Int String
  | RemoveCompletedEntries
  | ToggleEntries Bool

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NewLocation location ->
      { model | visible = toVisibility location } ! []

    SetDescription description ->
      { model | description = description } ! []

    AddEntry ->
      let
        cleanDescription =
          String.trim model.description
      in
        if String.isEmpty cleanDescription then
          model ! []
        else
          { model
          | uid = model.uid + 1
          , description = ""
          , entries = model.entries ++ [ createEntry model.uid cleanDescription ]
          } ! []

    RemoveEntry uid ->
      { model
      | entries = List.filter (\entry -> entry.uid /= uid) model.entries
      } ! []

    ToggleEntry uid completed ->
      let
        updateEntry entry =
          if entry.uid == uid then
            { entry | completed = completed }
          else
            entry
      in
        { model | entries = List.map updateEntry model.entries } ! []

    EditEntry uid description ->
      { model | mode = Edit uid description } ! []

    RemoveCompletedEntries ->
      { model | entries = List.filter (not << .completed) model.entries } ! []

    ToggleEntries completed ->
      let
        updateEntry entry =
          { entry | completed = completed }
      in
        { model | entries = List.map updateEntry model.entries } ! []

createEntry : Int -> String -> Entry
createEntry uid description =
  { uid = uid, description = description, completed = False }

-- VIEW

view : Model -> Html Msg
view { description, mode, visible, entries } =
  div []
    [ viewPrompt description
    , viewBody mode visible entries
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

viewBody : Mode -> Visibility -> List Entry -> Html Msg
viewBody mode visible entries =
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
              (\entry -> (toString entry.uid, li [] [ viewEntry mode entry ]))
              (keep visible entries)
      , viewNumIncompleteEntries entries
      , viewVisibilityFilters visible
      , button
          [ type_ "button"
          , Events.onClick RemoveCompletedEntries
          ]
          [ text "Clear completed" ]
      ]

viewEntry : Mode -> Entry -> Html Msg
viewEntry mode entry =
  case mode of
    Normal ->
      viewEntryNormal entry

    Edit uid description ->
      if uid == entry.uid then
        viewEntryEdit description
      else
        viewEntryNormal entry

viewEntryNormal : Entry -> Html Msg
viewEntryNormal { uid, description, completed } =
  div [ class "hover-target" ]
    [ input
        [ type_ "checkbox"
        , checked completed
        , Events.onCheck (ToggleEntry uid)
        ]
        []
    , span
        [ classList [ ("line-through", completed) ]
        , Events.onDoubleClick (EditEntry uid description)
        ]
        [ text description ]
    , button
        [ type_ "button"
        , class "ml-1 visible-on-hover"
        , Events.onClick (RemoveEntry uid)
        ]
        [ text "x" ]
    ]

viewEntryEdit : String -> Html msg
viewEntryEdit description =
  Html.form []
    [ input
        [ type_ "text"
        , value description
        ]
        []
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

viewVisibilityFilters : Visibility -> Html Msg
viewVisibilityFilters selected =
  div []
    [ viewVisibilityFilter "All" "#/" All selected
    , text " "
    , viewVisibilityFilter "Active" "#/active" Active selected
    , text " "
    , viewVisibilityFilter "Completed" "#/completed" Completed selected
    ]

viewVisibilityFilter : String -> String -> Visibility -> Visibility -> Html Msg
viewVisibilityFilter name url current selected =
  if current == selected then
    span [] [ text name ]
  else
    a [ href url ] [ text name ]

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

toVisibility : Navigation.Location -> Visibility
toVisibility { hash } =
  case String.dropLeft 2 hash of
    "active" ->
      Active

    "completed" ->
      Completed

    _ ->
      All
