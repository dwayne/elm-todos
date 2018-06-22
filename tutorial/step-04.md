# Step 4

## Goal

To be able to mark entries as completed.

## Plan

1. Introduce the `Entry` record.
2. Display a check box next to each entry.
3. Attempt 1 - Mark an entry as completed.
4. Attempt 2 - Mark an entry as completed.
5. Display completed entries with a line through their description.

## Introduce the `Entry` record

So far an entry consists solely of its description. To be able to know whether or not an entry is completed we need to track that somewhere.

To do so, we introduce an `Entry` record with fields for a `description` and a `completed` flag.

```elm
type alias Entry =
  { description : String
  , completed : Bool
  }
```

Then, we update the `Model` so that the `entries` field represents a `List Entry` rather than a `List String`.

```elm
type alias Model =
  { description : String
  , entries : List Entry
  }
```

Finally, for everything else to continue to work we make the following changes:

```elm
update msg model =
  case msg of
    -- ...

    AddEntry ->
      let
        -- ...
      in
        if String.isEmpty cleanDescription then
          -- ...
        else
          { model
          | description = ""
          , entries = model.entries ++ [ createEntry cleanDescription ]
          }

createEntry : String -> Entry
createEntry description =
  { description = description, completed = False }

view { description, entries } =
  div []
    [ -- ...
    , ul [] (List.map (\entry -> li [] [ viewEntry entry ]) entries)
    ]

viewEntry : Entry -> Html msg
viewEntry { description } =
  text description
```

At this point you should check that the application works exactly as before.

## Display a check box next to each entry

All entries are created with their `completed` field set to `False`. And, we currently have no way in the UI to change that value. As a first step we'd display a check box next to each entry so that when the box is clicked we can update the `completed` field of the corresponding entry.

```elm
viewEntry { description, completed } =
  div []
    [ input
        [ type_ "checkbox"
        , checked completed
        ]
        []
    , text description
    ]
```

Compile and view the result in your browser.

Add entries and check off some of them.

Take a look at the debug panel and you'd notice that no messages were sent when you checked off the entries. Also, each entry's `completed` field remains equal to `False`.

We'd fix these issues in the next two steps.

## Attempt 1 - Mark an entry as completed

We can capture [change events](https://developer.mozilla.org/en-US/docs/Web/Events/change) on check boxes by adding the [onCheck](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html-Events#onCheck) event handler to them.

The `onCheck` event handler takes a function of the form `Bool -> msg`. The function is used to wrap the `event.target.checked` value of the check box in a message defined by your message type.

Here's what we'd do.

1. Add a new message to our `Msg` type, `ToggleEntry Bool`.
2. Add an `onCheck` event handler to each entry's check box and have it send `ToggleEntry` messages to our `update` function whenever it's checked.
3. Add a case to process `ToggleEntry` messages in our `update` function.

```elm
-- 1
type Msg
  = SetDescription String
  | AddEntry
  | ToggleEntry Bool

-- 2
viewEntry : Entry -> Html Msg
viewEntry { description, completed } =
  div []
    [ input
        [ type_ "checkbox"
        , checked completed
        , Events.onCheck ToggleEntry
        ]
        []
    , text description
    ]

-- 3
update msg model =
  case msg of
    -- ...

    ToggleEntry completed ->
      -- Hmmm. Which entry do we update?
      model
```

We seem to have a little problem. We currently have no way of knowing which entry's `completed` field to update.

Do you have any ideas?

Take some time to think about it before moving on.

## Attempt 2 - Mark an entry as completed

One way that we can solve the problem is by giving each entry a unique identifier on creation. When the check box for a given entry is clicked we'd send along the unique identifier for that entry via the `ToggleEntry` message. In this way, when we process the `ToggleEntry` message we'd be able to identify which entry's `completed` field to update.

Here are the changes we need to make:

```elm
type alias Model =
  { uid : Int -- The source of unique IDs
  , -- ...
  }

type alias Entry =
  { uid : Int -- A unique ID per entry
  , -- ...
  }

model =
  { uid = 0 -- IDs start from 0
  , -- ...
  }

type Msg
  = -- ...
  -- Keep track of which entry's completed field to update
  | ToggleEntry Int Bool

update msg model =
  case msg of
    -- ...

    AddEntry ->
      let
        cleanDescription =
          String.trim model.description
      in
        if String.isEmpty cleanDescription then
          model
        else
          { model
          -- Update our source of unique IDs
          | uid = model.uid + 1
          , description = ""
                                       -- Create the entry with a unique ID
          , entries = model.entries ++ [ createEntry model.uid cleanDescription ]
          }

    ToggleEntry uid completed ->
      let
        updateEntry entry =
          if entry.uid == uid then
            -- We've found the entry whose completed field to update
            { entry | completed = completed }
          else
            -- Not the entry whose check box was clicked
            entry
      in
        { model | entries = List.map updateEntry model.entries }

createEntry : Int -> String -> Entry
createEntry uid description =
  { uid = uid, description = description, completed = False }

viewEntry { uid, description, completed } =
  div []
    [ input
        [ -- ...
        -- By partially applying ToggleEntry we can fix the ID that's used
        -- when messages are generated due to clicking on a given entry's check box
        , Events.onCheck (ToggleEntry uid)
        ]
        []
    , -- ...
    ]
```

`ToggleEntry uid` makes use of the fact that

1. `ToggleEntry` is a (curried) function of type `Int -> Bool -> Msg`, and
2. Functions in Elm can be partially applied.

As a result, `ToggleEntry uid` is a function of type `Bool -> Msg` which is precisely the type of the first argument accepted by the `onCheck` event handler.

You can learn more about *currying* and *partial application* [here](https://en.wikipedia.org/wiki/Currying).

Compile and view the result in your browser. This time when you add a few entries and check some of them off you'd see the changes reflected in the model when you open the debug panel.

There's just one more thing we need to do before we can wrap up.

## Display completed entries with a line through their description

We should give the user a stronger cue that a given entry is completed other than the check box being checked. One simple way to accomplish that is to display completed entries with a line through their description.

Here are the changes we'd need to make:

```elm
viewEntry { uid, description, completed } =
  div []
    [ -- ...
    , span
        [ classList [ ("line-through", completed) ] ]
        [ text description ]
    ]
```

We use [classList](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html-Attributes#classList) to add or remove the `line-through` class based on whether or not `completed` is `True` or `False` respectively.

Then, add a `todo.css` in the same directory as `index.html` with the following contents:

```css
.line-through {
  text-decoration: line-through;
}
```

Finally, update `index.html`.

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <!-- ... -->

    <title>Elm Todos</title>

    <link rel="stylesheet" href="todo.css">
  </head>
  <body>
    <!-- ... -->
  </body>
</html>
```

Compile and check out the changes one more time to see that it all works as expected.

Congratulations! You've completed step 4.
