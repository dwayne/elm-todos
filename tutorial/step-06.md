# Step 6

## Goal

To add a variety of useful features.

## Plan

1. Add a check box to simultaneously update the completed field of each entry.
2. Add a button to remove all the completed entries.
3. Display the number of incomplete entries.
4. When there are no entries, only display the prompt.

## Add a check box to simultaneously update the completed field of each entry

Let's put a check box right under the prompt.

```elm
view { description, entries } =
  div []
    [ Html.form -- ...
    , label []
        [ input
           [ type_ "checkbox"
           , checked (List.all .completed entries)
           , Events.onCheck ToggleEntries
           ]
           []
        , text "Mark all as completed"
        ]
    , ul -- ...
    ]
```

`List.all .completed entries` returns `True` if and only if all the entries are completed. We wrap the check box in a label so that we can also click the text "Mark all as completed" to toggle it.

To complete the implementation of the feature we add a new `ToggleEntries` message and write a case to handle it in the `update` function.

```elm
type Msg
  = -- ...
  | ToggleEntries Bool

update msg model =
  case msg of
    -- ...

    ToggleEntries completed ->
      let
        updateEntry entry =
          { entry | completed = completed }
      in
        { model | entries = List.map updateEntry model.entries }
```

Compile and try it out in your browser.

## Add a button to remove all the completed entries

Update the view.

```elm
view { description, entries } =
  div []
    [ Html.form -- ...
    , label -- ...
    , ul -- ...
    , button
        [ type_ "button"
        , Events.onClick RemoveCompletedEntries
        ]
        [ text "Clear completed" ]
```

Add the new `RemoveCompletedEntries` message and write a case to handle it in the `update` function.

```elm
type Msg
  = -- ...
  | RemoveCompletedEntries
  | ToggleEntries Bool

update msg model =
  case msg of
    -- ...

    RemoveCompletedEntries ->
      { model | entries = List.filter (not << .completed) model.entries }

    ToggleEntries completed ->
      -- ...
```

The anonymous function created by `not << .completed` is equivalent to `\entry -> not entry.completed`.

You can learn more about `<<`, [here](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Basics#%3C%3C).

Compile and try it out in your browser.

## Display the number of incomplete entries

We'd add a message right under the list of entries that tells the user how many entries are left to be completed. Here are the requirements:

1. When there are 0 entries the message should be "0 tasks left".
2. When there is 1 entry the message should be "1 task left".
3. When there is more than 1 entry, say n, the message should be "n tasks left".

**N.B.** *I refer to the to-do items as entries in the code but in the UI I rather refer to them as tasks. I hope that doesn't confuse you.*

Firstly, we'd add a `pluralize` helper function.

```elm
-- HELPERS

pluralize : Int -> String -> String -> String
pluralize n singular plural =
  if n == 1 then
    singular
  else
    plural

-- pluralize 0 "task" "tasks" = "tasks"
-- pluralize 1 "task" "tasks" = "task"
-- pluralize 2 "task" "tasks" = "tasks"
-- etc
```

Then, we'd add the text to the view.

```elm
view { description, entries } =
  div []
    [ Html.form -- ...
    , label -- ...
    , ul -- ...
    , viewNumIncompleteEntries entries
    , button -- ...
    ]

viewNumIncompleteEntries : List Entry -> Html msg
viewNumIncompleteEntries entries =
  let
    n =
      entries
        |> List.filter (not << .completed)
        |> List.length
  in
    div []
      [ text <| toString n ++ " " ++ pluralize n "task" "tasks" ++ " left" ]
```

We make use of the `|>` operator to build a pipeline to calculate, `n`, the number of incomplete entries.

```elm
entries
  |> List.filter (.completed >> not)
  |> List.length

-- is equivalent to

List.length (List.filter (\entry -> not entry.completed) entries)
```

- Learn more about `|>`, i.e. forward function application, [here](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Basics#|%3E). It's helpful because it usually makes the code easier to read. For e.g. it makes [elm-decode-pipeline](http://package.elm-lang.org/packages/NoRedInk/elm-decode-pipeline/latest) really nice to use.

Compile and try it out in your browser.

## When there are no entries, only display the prompt

When there are no entries there's no need to display anything other than the prompt.

Also, while we're at it we'd refactor the view.

```elm
view : Model -> Html Msg
view { description, entries } =
  div []
    [ viewPrompt description
    , viewBody entries
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

viewBody : List Entry -> Html Msg
viewBody entries =
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
      , ul [] (List.map (\entry -> li [] [ viewEntry entry ]) entries)
      , viewNumIncompleteEntries entries
      , button
          [ type_ "button"
          , Events.onClick RemoveCompletedEntries
          ]
          [ text "Clear completed" ]
      ]
```

Compile and try it out in your browser.

Congratulations! You've completed step 6.
