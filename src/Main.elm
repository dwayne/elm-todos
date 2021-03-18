port module Main exposing (main)


import Browser
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as E
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Task
import Url exposing (Url)


main : Program Flags Model Msg
main =
  Browser.application
    { init = init
    , update = updateAndSave
    , view = view
    , subscriptions = always Sub.none
    , onUrlRequest = ClickedLink
    , onUrlChange = ChangedUrl
    }


-- MODEL


type alias Model =
  { url : Url
  , key : Nav.Key
  , uid : Int
  , description : String
  , mode : Mode
  , visible : Visibility
  , entries : List Entry
  }


type Mode
  = Normal
  | Edit Int String


type alias Entry =
  { uid : Int
  , description : String
  , completed : Bool
  }


type Visibility
  = All
  | Active
  | Completed


type alias Flags =
  Maybe Encode.Value


init : Flags -> Url -> Nav.Key -> (Model, Cmd msg)
init savedState url key =
  let
    initModel =
      Model url key 0 "" Normal (toVisibility url) []
  in
  ( case savedState of
      Nothing ->
        initModel

      Just value ->
        case Decode.decodeValue (modelDecoder url key) value of
          Ok model ->
            model

          Err e ->
            initModel
  , Cmd.none
  )


toVisibility : Url -> Visibility
toVisibility url =
  case (url.path, url.fragment) of
    ("/", Just "/active") ->
      Active

    ("/", Just "/completed") ->
      Completed

    _ ->
      All


-- UPDATE


type Msg
  = ClickedLink Browser.UrlRequest
  | ChangedUrl Url
  | ChangedDescription String
  | SubmittedDescription
  | CheckedEntry Int Bool
  | ClickedRemoveButton Int
  | CheckedMarkAllCompleted Bool
  | ClickedRemoveCompletedEntriesButton
  | DoubleClickedDescription Int String
  | Focus (Result Dom.Error ())
  | ChangedEntryDescription Int String
  | SubmittedEditedDescription
  | BlurredEntry
  | EscapedEntry


updateAndSave : Msg -> Model -> (Model, Cmd Msg)
updateAndSave msg model =
  let
    (nextModel, cmd) =
      update msg model
  in
  ( nextModel
  , Cmd.batch [cmd, save (encodeModel nextModel)]
  )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    ClickedLink urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          ( model
          , Nav.pushUrl model.key (Url.toString url)
          )

        Browser.External href ->
          ( model
          , Nav.load href
          )

    ChangedUrl url ->
      ( { model | visible = toVisibility url }
      , Cmd.none
      )

    ChangedDescription description ->
      ( { model | description = description }
      , Cmd.none
      )

    SubmittedDescription ->
      let
        cleanDescription =
          String.trim model.description
      in
      if String.isEmpty cleanDescription then
        ( model
        , Cmd.none
        )
      else
        ( { model
          | uid = model.uid + 1
          , description = ""
          , entries = model.entries ++ [ createEntry model.uid cleanDescription ]
          }
        , Cmd.none
        )

    CheckedEntry uid isChecked ->
      let
        updateEntry entry =
          if uid == entry.uid then
            { entry | completed = isChecked }
          else
            entry
      in
      ( { model | entries = List.map updateEntry model.entries }
      , Cmd.none
      )

    ClickedRemoveButton uid ->
      ( { model
        | entries = List.filter (\entry -> entry.uid /= uid) model.entries
        }
      , Cmd.none
      )

    CheckedMarkAllCompleted isChecked ->
      let
        updateEntry entry =
          { entry | completed = isChecked }
      in
      ( { model | entries = List.map updateEntry model.entries }
      , Cmd.none
      )

    ClickedRemoveCompletedEntriesButton ->
      ( { model | entries = List.filter (not << .completed) model.entries }
      , Cmd.none
      )

    DoubleClickedDescription uid description ->
      ( { model | mode = Edit uid description }
      , focus (entryEditId uid)
      )

    Focus (Ok ()) ->
      ( model
      , Cmd.none
      )

    Focus (Err (Dom.NotFound e)) ->
      ( model
      , Cmd.none
      )

    ChangedEntryDescription uid description ->
      ( { model | mode = Edit uid description }
      , Cmd.none
      )

    SubmittedEditedDescription ->
      case model.mode of
        Normal ->
          ( model
          , Cmd.none
          )

        Edit uid description ->
          let
            cleanDescription =
              String.trim description

            updateEntry entry =
              if uid == entry.uid then
                { entry | description = cleanDescription }
              else
                entry
          in
          if String.isEmpty cleanDescription then
            ( { model
              | mode = Normal
              , entries = List.filter (\entry -> entry.uid /= uid) model.entries
              }
            , Cmd.none
            )
          else
            ( { model
              | mode = Normal
              , entries = List.map updateEntry model.entries
              }
            , Cmd.none
            )

    BlurredEntry ->
      ( { model | mode = Normal }
      , Cmd.none
      )

    EscapedEntry ->
      ( { model | mode = Normal }
      , Cmd.none
      )


createEntry : Int -> String -> Entry
createEntry uid description =
  Entry uid description False


focus : String -> Cmd Msg
focus htmlId =
  Task.attempt Focus (Dom.focus htmlId)


-- PORTS


port save : Encode.Value -> Cmd msg


-- ENCODERS


encodeModel : Model -> Encode.Value
encodeModel { uid, description, mode, visible, entries } =
  Encode.object
    [ ("uid", Encode.int uid)
    , ("description", Encode.string description)
    , ("mode", encodeMode mode)
    , ("visible", encodeVisibility visible)
    , ("entries", Encode.list encodeEntry entries)
    ]


encodeMode : Mode -> Encode.Value
encodeMode mode =
  case mode of
    Normal ->
      Encode.object [("ctor", Encode.string "Normal")]

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


-- DECODERS


modelDecoder : Url -> Nav.Key -> Decoder Model
modelDecoder url key =
  Decode.map7 Model
    (Decode.succeed url)
    (Decode.succeed key)
    (Decode.field "uid" Decode.int)
    (Decode.field "description" Decode.string)
    (Decode.field "mode" modeDecoder)
    (Decode.succeed (toVisibility url))
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
              Decode.fail ("Unknown mode: " ++ s)
        )


entryDecoder : Decoder Entry
entryDecoder =
  Decode.map3 Entry
    (Decode.field "uid" Decode.int)
    (Decode.field "description" Decode.string)
    (Decode.field "completed" Decode.bool)


-- VIEW


view : Model -> Browser.Document Msg
view { description, mode, visible, entries } =
  { title = "Elm Todos"
  , body =
      [ section [ class "todoapp" ] <|
          [ viewPrompt description
          ] ++ viewMain mode visible entries
      , viewFooter
      ]
  }


viewPrompt : String -> Html Msg
viewPrompt description =
  header [ class "header" ]
    [ h1 [] [ text "todos" ]
    , Html.form [ E.onSubmit SubmittedDescription ]
        [ input
            [ type_ "text"
            , autofocus True
            , placeholder "What needs to be done?"
            , class "new-todo"
            , value description
            , E.onInput ChangedDescription
            ]
            []
        ]
    ]


viewMain : Mode -> Visibility -> List Entry -> List (Html Msg)
viewMain mode visible entries =
  if List.isEmpty entries then
    []
  else
    [ section [ class "main" ]
        [ input
            [ type_ "checkbox"
            , id "toggle-all"
            , class "toggle-all"
            , checked (List.all .completed entries)
            , E.onCheck CheckedMarkAllCompleted
            ]
            []
        , label [ for "toggle-all" ] [ text "Mark all as completed" ]
        , ul [ class "todo-list" ] <|
            List.map
              (\entry ->
                li
                  [ classList
                      [ ("completed", entry.completed)
                      , ("editing", isEditing mode entry)
                      ]
                  ]
                  [ viewEntry mode entry ]
              )
              (keep visible entries)
        ]
    , footer [ class "footer" ] <|
        [ viewStatus entries
        , viewVisibilityFilters visible
        ] ++ viewClearCompleted entries
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
  div [ class "view" ]
    [ input
        [ type_ "checkbox"
        , checked completed
        , class "toggle"
        , E.onCheck (CheckedEntry uid)
        ]
        []
    , label [ E.onDoubleClick (DoubleClickedDescription uid description) ]
        [ text description ]
    , button
        [ type_ "button"
        , class "destroy"
        , E.onClick (ClickedRemoveButton uid)
        ]
        []
    ]


viewEntryEdit : Int -> String -> Html Msg
viewEntryEdit uid description =
  Html.form [ E.onSubmit SubmittedEditedDescription ]
    [ input
        [ type_ "text"
        , id (entryEditId uid)
        , value description
        , class "edit"
        , E.onInput (ChangedEntryDescription uid)
        , E.onBlur BlurredEntry
        , onEsc EscapedEntry
        ]
        []
    ]


viewStatus : List Entry -> Html msg
viewStatus entries =
  let
    n =
      entries
        |> List.filter (not << .completed)
        |> List.length
  in
  span [ class "todo-count" ]
    [ strong [] [ text (String.fromInt n) ]
    , text <| " " ++ pluralize n "item" "items" ++ " left"
    ]


viewVisibilityFilters : Visibility -> Html msg
viewVisibilityFilters selected =
  ul [ class "filters" ]
    [ li [] [ viewVisibilityFilter "All" "#/" All selected ]
    , li [] [ viewVisibilityFilter "Active" "#/active" Active selected ]
    , li [] [ viewVisibilityFilter "Completed" "#/completed" Completed selected ]
    ]


viewVisibilityFilter : String -> String -> Visibility -> Visibility -> Html msg
viewVisibilityFilter name url current selected =
  if current == selected then
    span [ class "selected" ] [ text name ]
  else
    a [ href url ] [ text name ]


viewClearCompleted : List Entry -> List (Html Msg)
viewClearCompleted entries =
  let
    completedEntries =
      List.filter .completed entries

    numCompletedEntries =
      List.length completedEntries
  in
  if numCompletedEntries == 0 then
    []
  else
    [ button
        [ type_ "button"
        , class "clear-completed"
        , E.onClick ClickedRemoveCompletedEntriesButton
        ]
        [ text <| "Clear completed (" ++ String.fromInt numCompletedEntries ++ ")" ]
    ]


viewFooter : Html msg
viewFooter =
  footer [ class "info" ]
    [ p [] [ text "Double-click to edit a todo" ]
    , p []
        [ text "Written by "
        , a [ href "https://github.com/dwayne" ] [ text "Dwayne Crooks" ]
        ]
    ]


-- HELPERS


entryEditId : Int -> String
entryEditId uid =
  "entry-edit-" ++ String.fromInt uid


isEditing : Mode -> Entry -> Bool
isEditing mode entry =
  case mode of
    Normal ->
      False

    Edit uid _ ->
      uid == entry.uid


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
  E.on "keydown" (Decode.andThen isEsc E.keyCode)
