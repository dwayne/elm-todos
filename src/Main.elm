module Main exposing (main)


import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as E
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


init : flags -> Url -> Nav.Key -> (Model, Cmd msg)
init _ url key =
  ( Model url key 0 "" All []
  , Cmd.none
  )


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
  | ClickedVisibilityFilter Visibility


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
      ( Debug.log (Url.toString url) model
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

    ClickedVisibilityFilter visible ->
      ( { model | visible = visible }
      , Cmd.none
      )


createEntry : Int -> String -> Entry
createEntry uid description =
  Entry uid description False


-- VIEW


view : Model -> Browser.Document Msg
view { description, visible, entries } =
  { title = "Elm Todos"
  , body =
      [ div []
          [ viewPrompt description
          , viewBody visible entries
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
      , viewVisibilityFilters visible
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
    a [ href url, E.onClick (ClickedVisibilityFilter current) ] [ text name ]


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
