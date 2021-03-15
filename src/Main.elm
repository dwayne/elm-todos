module Main exposing (main)


import Browser
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as E
import Task
import Url exposing (Url)


main : Program () Model Msg
main =
  Browser.application
    { init = init
    , update = update
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


init : flags -> Url -> Nav.Key -> (Model, Cmd msg)
init _ url key =
  ( Model url key 0 "" Normal (toVisibility url) []
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
      Debug.log
        ("The element to focus was not found: " ++ e)
        ( model
        , Cmd.none
        )


createEntry : Int -> String -> Entry
createEntry uid description =
  Entry uid description False


focus : String -> Cmd Msg
focus htmlId =
  Task.attempt Focus (Dom.focus htmlId)


-- VIEW


view : Model -> Browser.Document Msg
view { description, mode, visible, entries } =
  { title = "Elm Todos"
  , body =
      [ div []
          [ viewPrompt description
          , viewBody mode visible entries
          ]
      ]
  }


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
              , E.onCheck CheckedMarkAllCompleted
              ]
              []
          , text "Mark all as completed"
          ]
      , ul [] <|
          List.map
            (\entry -> li [] [ viewEntry mode entry ])
            (keep visible entries)
      , viewStatus entries
      , viewVisibilityFilters visible
      , button
          [ type_ "button"
          , E.onClick ClickedRemoveCompletedEntriesButton
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
        , E.onCheck (CheckedEntry uid)
        ]
        []
    , span
        [ classList [ ("line-through", completed) ]
        , E.onDoubleClick (DoubleClickedDescription uid description)
        ]
        [ text description ]
    , button
        [ type_ "button"
        , class "ml-1 visible-on-hover"
        , E.onClick (ClickedRemoveButton uid)
        ]
        [ text "x" ]
    ]


viewEntryEdit : Int -> String -> Html Msg
viewEntryEdit uid description =
  Html.form []
    [ input
        [ type_ "text"
        , id (entryEditId uid)
        , value description
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
  div []
    [ text <| String.fromInt n ++ " " ++ pluralize n "task" "tasks" ++ " left" ]


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


entryEditId : Int -> String
entryEditId uid =
  "entry-edit-" ++ String.fromInt uid


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
