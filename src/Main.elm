port module Main exposing (main)

import Browser as B
import Browser.Dom as BD
import Browser.Navigation as BN
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import Json.Encode as JE
import Task
import Url exposing (Url)


main : Program Flags Model Msg
main =
    B.application
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
    , key : BN.Key
    , uid : Int
    , description : String
    , mode : Mode
    , visibility : Visibility
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
    Maybe JE.Value


init : Flags -> Url -> BN.Key -> ( Model, Cmd msg )
init savedState url key =
    let
        initModel =
            Model url key 0 "" Normal (toVisibility url) []
    in
    ( case savedState of
        Nothing ->
            initModel

        Just value ->
            case JD.decodeValue (modelDecoder url key) value of
                Ok model ->
                    model

                Err e ->
                    initModel
    , Cmd.none
    )


toVisibility : Url -> Visibility
toVisibility url =
    case ( url.path, url.fragment ) of
        ( "/", Just "/active" ) ->
            Active

        ( "/", Just "/completed" ) ->
            Completed

        _ ->
            All



-- UPDATE


type Msg
    = ClickedLink B.UrlRequest
    | ChangedUrl Url
    | ChangedDescription String
    | SubmittedDescription
    | CheckedEntry Int Bool
    | ClickedRemoveButton Int
    | CheckedMarkAllCompleted Bool
    | ClickedRemoveCompletedEntriesButton
    | DoubleClickedDescription Int String
    | Focus (Result BD.Error ())
    | ChangedEntryDescription Int String
    | SubmittedEditedDescription
    | BlurredEntry
    | EscapedEntry


updateAndSave : Msg -> Model -> ( Model, Cmd Msg )
updateAndSave msg model =
    let
        ( nextModel, cmd ) =
            update msg model
    in
    ( nextModel
    , Cmd.batch [ cmd, save (encodeModel nextModel) ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                B.Internal url ->
                    ( model
                    , BN.pushUrl model.key (Url.toString url)
                    )

                B.External href ->
                    ( model
                    , BN.load href
                    )

        ChangedUrl url ->
            ( { model | visibility = toVisibility url }
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

        Focus (Err (BD.NotFound e)) ->
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
    Task.attempt Focus (BD.focus htmlId)



-- PORTS


port save : JE.Value -> Cmd msg



-- ENCODERS


encodeModel : Model -> JE.Value
encodeModel { uid, description, mode, visibility, entries } =
    JE.object
        [ ( "uid", JE.int uid )
        , ( "description", JE.string description )
        , ( "mode", encodeMode mode )
        , ( "visibility", encodeVisibility visibility )
        , ( "entries", JE.list encodeEntry entries )
        ]


encodeMode : Mode -> JE.Value
encodeMode mode =
    case mode of
        Normal ->
            JE.object [ ( "ctor", JE.string "Normal" ) ]

        Edit uid description ->
            JE.object
                [ ( "ctor", JE.string "Edit" )
                , ( "0", JE.int uid )
                , ( "1", JE.string description )
                ]


encodeVisibility : Visibility -> JE.Value
encodeVisibility visibility =
    case visibility of
        All ->
            JE.string "all"

        Active ->
            JE.string "active"

        Completed ->
            JE.string "completed"


encodeEntry : Entry -> JE.Value
encodeEntry { uid, description, completed } =
    JE.object
        [ ( "uid", JE.int uid )
        , ( "description", JE.string description )
        , ( "completed", JE.bool completed )
        ]



-- DECODERS


modelDecoder : Url -> BN.Key -> JD.Decoder Model
modelDecoder url key =
    JD.map7 Model
        (JD.succeed url)
        (JD.succeed key)
        (JD.field "uid" JD.int)
        (JD.field "description" JD.string)
        (JD.field "mode" modeDecoder)
        (JD.succeed (toVisibility url))
        (JD.field "entries" (JD.list entryDecoder))


modeDecoder : JD.Decoder Mode
modeDecoder =
    JD.field "ctor" JD.string
        |> JD.andThen
            (\s ->
                case s of
                    "Normal" ->
                        JD.succeed Normal

                    "Edit" ->
                        JD.map2 Edit
                            (JD.field "0" JD.int)
                            (JD.field "1" JD.string)

                    _ ->
                        JD.fail ("Unknown mode: " ++ s)
            )


entryDecoder : JD.Decoder Entry
entryDecoder =
    JD.map3 Entry
        (JD.field "uid" JD.int)
        (JD.field "description" JD.string)
        (JD.field "completed" JD.bool)



-- VIEW


view : Model -> B.Document Msg
view { description, mode, visibility, entries } =
    { title = "Elm Todos"
    , body =
        [ H.section [ HA.class "todoapp" ] <|
            [ viewPrompt description
            ]
                ++ viewMain mode visibility entries
        , viewFooter
        ]
    }


viewPrompt : String -> H.Html Msg
viewPrompt description =
    H.header [ HA.class "header" ]
        [ H.h1 [] [ H.text "todos" ]
        , H.form [ HE.onSubmit SubmittedDescription ]
            [ H.input
                [ HA.type_ "text"
                , HA.autofocus True
                , HA.placeholder "What needs to be done?"
                , HA.class "new-todo"
                , HA.value description
                , HE.onInput ChangedDescription
                ]
                []
            ]
        ]


viewMain : Mode -> Visibility -> List Entry -> List (H.Html Msg)
viewMain mode visibility entries =
    if List.isEmpty entries then
        []

    else
        [ H.section [ HA.class "main" ]
            [ H.input
                [ HA.type_ "checkbox"
                , HA.id "toggle-all"
                , HA.class "toggle-all"
                , HA.checked (List.all .completed entries)
                , HE.onCheck CheckedMarkAllCompleted
                ]
                []
            , H.label [ HA.for "toggle-all" ] [ H.text "Mark all as completed" ]
            , H.ul [ HA.class "todo-list" ] <|
                List.map
                    (\entry ->
                        H.li
                            [ HA.classList
                                [ ( "completed", entry.completed )
                                , ( "editing", isEditing mode entry )
                                ]
                            ]
                            [ viewEntry mode entry ]
                    )
                    (keep visibility entries)
            ]
        , H.footer [ HA.class "footer" ] <|
            [ viewStatus entries
            , viewVisibilityFilters visibility
            ]
                ++ viewClearCompleted entries
        ]


viewEntry : Mode -> Entry -> H.Html Msg
viewEntry mode entry =
    case mode of
        Normal ->
            viewEntryNormal entry

        Edit uid description ->
            if uid == entry.uid then
                viewEntryEdit uid description

            else
                viewEntryNormal entry


viewEntryNormal : Entry -> H.Html Msg
viewEntryNormal { uid, description, completed } =
    H.div [ HA.class "view" ]
        [ H.input
            [ HA.type_ "checkbox"
            , HA.checked completed
            , HA.class "toggle"
            , HE.onCheck (CheckedEntry uid)
            ]
            []
        , H.label [ HE.onDoubleClick (DoubleClickedDescription uid description) ]
            [ H.text description ]
        , H.button
            [ HA.type_ "button"
            , HA.class "destroy"
            , HE.onClick (ClickedRemoveButton uid)
            ]
            []
        ]


viewEntryEdit : Int -> String -> H.Html Msg
viewEntryEdit uid description =
    H.form [ HE.onSubmit SubmittedEditedDescription ]
        [ H.input
            [ HA.type_ "text"
            , HA.id (entryEditId uid)
            , HA.value description
            , HA.class "edit"
            , HE.onInput (ChangedEntryDescription uid)
            , HE.onBlur BlurredEntry
            , onEsc EscapedEntry
            ]
            []
        ]


viewStatus : List Entry -> H.Html msg
viewStatus entries =
    let
        n =
            entries
                |> List.filter (not << .completed)
                |> List.length
    in
    H.span [ HA.class "todo-count" ]
        [ H.strong [] [ H.text (String.fromInt n) ]
        , H.text <| " " ++ pluralize n "item" "items" ++ " left"
        ]


viewVisibilityFilters : Visibility -> H.Html msg
viewVisibilityFilters selected =
    H.ul [ HA.class "filters" ]
        [ H.li [] [ viewVisibilityFilter "All" "#/" All selected ]
        , H.li [] [ viewVisibilityFilter "Active" "#/active" Active selected ]
        , H.li [] [ viewVisibilityFilter "Completed" "#/completed" Completed selected ]
        ]


viewVisibilityFilter : String -> String -> Visibility -> Visibility -> H.Html msg
viewVisibilityFilter name url current selected =
    if current == selected then
        H.span [ HA.class "selected" ] [ H.text name ]

    else
        H.a [ HA.href url ] [ H.text name ]


viewClearCompleted : List Entry -> List (H.Html Msg)
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
        [ H.button
            [ HA.type_ "button"
            , HA.class "clear-completed"
            , HE.onClick ClickedRemoveCompletedEntriesButton
            ]
            [ H.text <| "Clear completed (" ++ String.fromInt numCompletedEntries ++ ")" ]
        ]


viewFooter : H.Html msg
viewFooter =
    H.footer [ HA.class "info" ]
        [ H.p [] [ H.text "Double-click to edit a todo" ]
        , H.p []
            [ H.text "Written by "
            , H.a [ HA.href "https://github.com/dwayne" ] [ H.text "Dwayne Crooks" ]
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
keep visibility entries =
    case visibility of
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


onEsc : msg -> H.Attribute msg
onEsc msg =
    let
        decoder =
            HE.keyCode
                |> JD.andThen
                    (\n ->
                        case n of
                            27 ->
                                JD.succeed msg

                            _ ->
                                JD.fail "ignored"
                    )
    in
    HE.on "keydown" decoder
