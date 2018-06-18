port module Todo exposing (main)

import Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Html.Keyed as Keyed
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Navigation
import Task

main : Program Flags Model Msg
main =
  Navigation.programWithFlags NewLocation
    { init = init
    , update = updateAndSave
    , view = view
    , subscriptions = always Sub.none
    }

-- MODEL

type alias Flags =
  Maybe Encode.Value

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

init : Flags -> Navigation.Location -> (Model, Cmd Msg)
init savedModel location =
  let
    visible =
      toVisibility location

    initModel =
      { uid = 0
      , description = ""
      , mode = Normal
      , visible = visible
      , entries = []
      }
  in
    case savedModel of
      Nothing ->
        initModel ! []

      Just value ->
        case Decode.decodeValue modelDecoder value of
          Ok model ->
            { model | visible = visible } ! []

          Err e ->
            (Debug.log ("Unable to restore the saved model: " ++ e) initModel) ! []

-- UPDATE

type Msg
  = NewLocation Navigation.Location
  | SetDescription String
  | AddEntry
  | RemoveEntry Int
  | ToggleEntry Int Bool
  | CancelEdit
  | EditEntry Int String
  | Focus (Result Dom.Error ())
  | SaveEdit Int String
  | SetDescriptionForEntry Int String
  | RemoveCompletedEntries
  | ToggleEntries Bool

updateAndSave : Msg -> Model -> (Model, Cmd Msg)
updateAndSave msg model =
  let
    (nextModel, cmd) =
      update msg model
  in
    nextModel ! [ cmd, save (encodeModel nextModel) ]

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

    CancelEdit ->
      { model | mode = Normal } ! []

    EditEntry uid description ->
      { model | mode = Edit uid description } ! [ focus uid ]

    Focus result ->
      case result of
        Ok () ->
          model ! []

        Err (Dom.NotFound e) ->
          Debug.log ("Unable to focus the input field: " ++ e)
            { model | mode = Normal } ! []

    SaveEdit uid description ->
      let
        cleanDescription =
          String.trim description

        updateEntry entry =
          if entry.uid == uid then
            { entry | description = cleanDescription }
          else
            entry
      in
        if String.isEmpty cleanDescription then
          { model | mode = Normal } ! []
        else
          { model
          | mode = Normal
          , entries = List.map updateEntry model.entries
          } ! []

    SetDescriptionForEntry uid description ->
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

-- DECODERS

modelDecoder : Decoder Model
modelDecoder =
  Decode.map5 Model
    (Decode.field "uid" Decode.int)
    (Decode.field "description" Decode.string)
    (Decode.field "mode" modeDecoder)
    (Decode.field "visible" visibilityDecoder)
    (Decode.field "entries" (Decode.list entryDecoder))

modeDecoder : Decoder Mode
modeDecoder =
  Decode.field "ctor" Decode.string
    |> Decode.andThen
        (\s ->
          case s of
            "Normal" ->
              Decode.succeed Normal

            "Edit" ->
              Decode.map2 Edit
                (Decode.field "0" Decode.int)
                (Decode.field "1" Decode.string)

            _ ->
              Decode.fail ("Unknown data constructor for mode: " ++ s)
        )

visibilityDecoder : Decoder Visibility
visibilityDecoder =
  Decode.string
    |> Decode.andThen
        (\s ->
          case s of
            "all" ->
              Decode.succeed All

            "active" ->
              Decode.succeed Active

            "completed" ->
              Decode.succeed Completed

            _ ->
              Decode.fail ("Unknown visibility: " ++ s)
        )

entryDecoder : Decoder Entry
entryDecoder =
  Decode.map3 Entry
    (Decode.field "uid" Decode.int)
    (Decode.field "description" Decode.string)
    (Decode.field "completed" Decode.bool)

-- ENCODERS

encodeModel : Model -> Encode.Value
encodeModel { uid, description, mode, visible, entries } =
  Encode.object
    [ ("uid", Encode.int uid)
    , ("description", Encode.string description)
    , ("mode", encodeMode mode)
    , ("visible", encodeVisibility visible)
    , ("entries", Encode.list (List.map encodeEntry entries))
    ]

encodeMode : Mode -> Encode.Value
encodeMode mode =
  case mode of
    Normal ->
      Encode.object [ ("ctor", Encode.string "Normal") ]

    Edit uid description ->
      Encode.object
        [ ("ctor", Encode.string "Edit")
        , ("0", Encode.int uid)
        , ("1", Encode.string description)
        ]

encodeVisibility : Visibility -> Encode.Value
encodeVisibility visible =
  case visible of
    All ->
      Encode.string "all"

    Active ->
      Encode.string "active"

    Completed ->
      Encode.string "completed"

encodeEntry : Entry -> Encode.Value
encodeEntry { uid, description, completed } =
  Encode.object
    [ ("uid", Encode.int uid)
    , ("description", Encode.string description)
    , ("completed", Encode.bool completed)
    ]

-- PORTS

port save : Encode.Value -> Cmd msg

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
        viewEntryEdit uid description
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

viewEntryEdit : Int -> String -> Html Msg
viewEntryEdit uid description =
  Html.form [ Events.onSubmit (SaveEdit uid description) ]
    [ input
        [ type_ "text"
        , id (htmlId uid)
        , value description
        , Events.onInput (SetDescriptionForEntry uid)
        , Events.onBlur CancelEdit
        , onEsc CancelEdit
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

focus : Int -> Cmd Msg
focus uid =
  Task.attempt Focus (Dom.focus (htmlId uid))

htmlId : Int -> String
htmlId uid =
  "edit-entry-" ++ toString uid

keep : Visibility -> List Entry -> List Entry
keep visible entries =
  case visible of
    All ->
      entries

    Active ->
      List.filter (not << .completed) entries

    Completed ->
      List.filter .completed entries

onEsc : msg -> Attribute msg
onEsc msg =
  let
    isEsc keyCode =
      case keyCode of
        27 ->
          Decode.succeed msg

        _ ->
          Decode.fail "Not ESC"
  in
    Events.on "keydown" (Decode.andThen isEsc Events.keyCode)

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
