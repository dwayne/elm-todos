# Step 9

## Goal

To be able to edit existing entries.

## Plan

1. Double click to edit an entry.
2. Change the return type of the update function.
3. Install `elm-lang/dom`.
4. Focus the input field on edit.
5. Temporarily change the description for the entry being edited.
6. Save the changes for the entry being edited.
7. Cancel the changes when the input field loses focus.
8. Cancel the changes when ESC is pressed in the input field.

## Double click to edit an entry

If we add a few entries and double click one of them then nothing interesting happens. Instead we want an input field to appear that would allow the user to edit the entry's description.

To do that we'd add a `mode` field to the `Model`. Its type would be a union type called `Mode` that would represent the two modes we want for the application, normal and edit mode.

In the normal mode we want the application to behave as it currently does.

In the edit mode we want the application to allow the user to edit the entry that was double clicked.

Let's add the `mode` field and the `Mode` union type.

```elm
type alias Model =
  { uid : Int
  , description : String
  -- 1. Add a mode field.
  , mode : Mode
  , visible : Visibility
  , entries : List Entry
  }

type Mode
  = Normal
  -- 2. Keep track of the entry being edited and its new description.
  | Edit Int String

init location =
  { uid = 0
  , description = ""
  -- 3. Start in the normal mode.
  , mode = Normal
  , visible = toVisibility location
  , entries = []
  } ! []
```

By default the application starts in the normal mode.

Now, let's update the views to handle the two modes.

```elm
view { description, mode, visible, entries } =
  div []
    [ viewPrompt description
    , viewBody mode visible entries
    ]

viewBody : Mode -> Visibility -> List Entry -> Html Msg
viewBody mode visible entries =
  if List.isEmpty entries then
    -- ...
  else
    div []
      [ -- ...
      , Keyed.ul []
          <| List.map
              (\entry -> (toString entry.uid, li [] [ viewEntry mode entry ]))
              (keep visible entries)
      , -- ...
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

        -- Double clicking on the entry's description causes an EditEntry
        -- message to be sent to the update function.
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

-- Show this when editing an entry.
viewEntryEdit : String -> Html Msg
viewEntryEdit description =
  Html.form []
    [ input
        [ type_ "text"
        , value description
        ]
        []
    ]
```

The key changes were:

1. To add an `onDoubleClick` event handler that sends a new `EditEntry` message when an entry's description is double clicked.
2. To add a view, `viewEntryEdit`, for editing an entry's description.

When we receive the `EditEntry` message we want to switch to the edit mode.

Let's add the new message to `Msg` and handle it in the `update` function.

```elm
type Msg
  = -- ...
  | EditEntry Int String

update msg model =
  case msg of ->
    -- ...

    EditEntry uid description ->
      { model | mode = Edit uid description }
```

Compile and try it out in your browser.

Add a few entries. Double click anyone of their descriptions to edit an entry. And, notice that an input field appears with the current description of the entry in it.

It would be nice if the input field is immediately given focus when it appears.

We're going to address that problem in the next three parts of the plan.

First, we're going to prepare the code for the upcoming changes. Then, we're going to install a package that helps us focus an HTML element. And, finally we're going to focus the input field on appearance.

## Change the return type of the update function

We're going to need to return a command in one of the cases in the `update` function. So, in preparation for that we're changing the `update` function's return type from `Model` to `(Model, Cmd Msg)`.

```elm
main =
  Navigation.programWithFlags NewLocation
    { init = init
    , update = update
    , view = view
    , subscriptions = always Sub.none
    }

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
```

## Install `elm-lang/dom`

```elm
$ elm-package install elm-lang/dom
```

This package is what would allow us to manually set the focus of the input field that appears when an entry's description is double clicked. It has a [Dom](http://package.elm-lang.org/packages/elm-lang/dom/1.1.1/Dom) module with a [focus](http://package.elm-lang.org/packages/elm-lang/dom/1.1.1/Dom#focus) [Task](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Task) that we'd be using.

## Focus the input field on edit

Now we can make the changes to manually set the focus of the input field on edit.

To know which input field to focus we must give it an identifier. We'd use the entry's `uid` to come up with a unique HTML [id](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/id).

```elm
viewEntry mode entry =
  case mode of
    Normal ->
      -- ...

    Edit uid description ->
      if uid == entry.uid then
        viewEntryEdit uid description
      else
        -- ...

viewEntryEdit : Int -> String -> Html msg
viewEntryEdit uid description =
  Html.form []
    [ input
        [ type_ "text"
        , id (htmlId uid)
        , value description
        ]
        []
    ]

-- HELPERS

htmlId : Int -> String
htmlId uid =
  "edit-entry-" ++ toString uid
```

Now that we have a way to uniquely identify the element we want to focus we need to tell Elm to focus the input field with that identifier.

When we double click the description the `EditEntry` message gets sent and that's when we switch to the edit mode. That's a good time to tell Elm to focus the input field.

```elm
import Dom
import Task

type Msg
  = -- ...
  | Focus (Result Dom.Error ())

update msg model =
  case msg of
    -- ...

    EditEntry uid description ->
      { model | mode = Edit uid description } ! [ focus uid ]

    Focus result ->
      case result of
        Ok () ->
          model ! []

        Err (Dom.NotFound e) ->
          Debug.log ("Unable to focus the input field: " ++ e)
            { model | mode = Normal } ! []

-- HELPERS

focus : Int -> Cmd Msg
focus uid =
  Task.attempt Focus (Dom.focus (htmlId uid))
```

Let's start with [Dom.focus](http://package.elm-lang.org/packages/elm-lang/dom/1.1.1/Dom#focus) and work our way from there to understand how it all works.

`Dom.focus` takes an `Id`, which is just a type alias for a `String`, that identifies a particular DOM node to give focus. It returns a `Task Error ()`.

`Task Error ()` could be understood as follows. `Error` refers to [Dom.Error](http://package.elm-lang.org/packages/elm-lang/dom/1.1.1/Dom#Error) which is a union type defined in the `Dom` module. `Error` represents the errors that can occur if we fail to focus the element. In this case the only error that can occur is a `NotFound` error. The `()` represents the unit type. The unit type has exactly one value, `()`, and it represents what is returned if the `Task` succeeds.

In order to get Elm to do the task we have to call it with one of [Task.perform](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Task#perform) or [Task.attempt](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Task#attempt). `Task.perform` is used on tasks that would never fail whereas `Task.attempt` is used on tasks that may fail. Since our task may fail we use `Task.attempt`. The second argument to `Task.attempt` is the task we want to run which in this case is `Dom.focus (htmlId uid)`. The first argument is the message we want to send to our update function when our task completes. Since our task's type is `Task Error ()` and our message type is `Msg`, it follows that the type of the first argument is `Result Error () -> Msg`. Hence, it follows why our `Focus` data constructor is defined in that way.

Finally, the `update` function.

In the `EditEntry` case we'd be now entering the edit mode. So it would make sense to attempt to focus the input field that would appear. That's why we return the `focus uid` command.

In the `Focus` case it means that we attempted to focus the input field and we now need to process the result. If the focus succeeded then there's nothing we need to do. However, if the focus failed (which should really only happen if we have a bug in our code) then we log (here we use [Debug.log](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Debug#log) but this is a good place to use a service like [Rollbar](https://rollbar.com/)) the reason why it failed and switch back to the normal mode.

At this point we can double click an entry's description and when the input field appears it is given the focus.

In the next two parts we'd write the code that will allow us to change the existing description and save those changes.

## Temporarily change the description for the entry being edited

When editing the description of an entry we don't want to make permanent changes to the entry's current description. That's why the `Edit` data constructor for the `Mode` type includes a value for the entry's edited description. That's the value we'd update when we change the description.

```elm
type Msg
  = -- ...
  | SetDescriptionForEntry Int String

update msg model =
  case msg of
    -- ...

    SetDescriptionForEntry uid description ->
      { model | mode = Edit uid description } ! []

viewEntryEdit : Int -> String -> Html Msg
viewEntryEdit uid description =
  Html.form []
    [ input
        [ -- ...
        , Events.onInput (SetDescriptionForEntry uid)
        ]
        []
    ]
```

## Save the changes for the entry being edited

So we've made our edits but if we press ENTER in the input field to save them then nothing happens. Here's the code to make it happen.

```elm
type Msg
  = -- ...
  | SaveEdit Int String

update msg model =
  case msg of
    -- ...

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

viewEntryEdit uid description =
  Html.form [ Events.onSubmit (SaveEdit uid description) ]
    [ input -- ...
    ]
```

When we press ENTER in the input field our `onSubmit` event handler sends the new `SaveEdit` message to our update function. The `SaveEdit` message holds on to the final edited description and the unique ID of the entry whose description is to be updated. In the `update` function we process the `SaveEdit` message by updating the correct entry's description (provided that the new description is non-empty).

The final two parts allow us to switch out of the edit mode and back into the normal mode anytime we want to stop editing an entry's description.

## Cancel the changes when the input field loses focus

Let's leave the edit mode if the input field loses focus.


```elm
type Msg
  = -- ...
  | CancelEdit

update msg model =
  case msg of
    -- ...

    CancelEdit ->
      { model | mode = Normal } ! []

viewEntryEdit uid description =
  Html.form [ {--} ]
    [ input
        [ -- ...
        , Events.onBlur CancelEdit
        ]
        []
    ]
```

## Cancel the changes when ESC is pressed in the input field

Let's leave the edit mode when ESC is pressed in the input field.

```elm
import Json.Decode as Decode

viewEntryEdit uid description =
  Html.form [ {--} ]
    [ input
        [ -- ...
        , onEsc CancelEdit
        ]
        []
    ]

-- HELPERS

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
```

**TODO:** *Explain how `onEsc` works.*

That's everything we need to do to add editing.

Compile and try it out in your browser.

Congratulations! You've completed step 9.
