# Step 5

## Goal

To be able to remove an entry.

## Plan

1. Add a button to remove an entry.
2. Show the button only when you hover over the entry.

## Add a button to remove an entry

Let's add a button to the right of the description for each entry.

On each button we'd add an `onClick` event handler which would cause a `RemoveEntry` message to be sent to our `update` function when the button is clicked.

```elm
type Msg
  = SetDescription String
  | AddEntry
  -- We keep track of the unique ID of the entry to be removed
  | RemoveEntry Int
  | ToggleEntry Int Bool

update msg model =
  case msg of
    -- ...

    AddEntry ->
      -- ...

    RemoveEntry uid ->
      -- TODO: Remove the entry with the given unique ID.
      Debug.log ("Remove entry: " ++ toString uid) model

    ToggleEntry uid completed ->
      -- ...

viewEntry { uid, description, completed } =
  div []
    [ input -- ...
    , span -- ...
    , button
        [ type_ "button"
        , class "ml-1"
        , Events.onClick (RemoveEntry uid)
        ]
        [ text "x" ]
    ]
```

The `ml-1` class has the following definition:

```css
.ml-1 {
  margin-left: 1rem;
}
```

Then, here's how we'd handle the `RemoveEntry` message in the `update` function.

```elm
RemoveEntry uid ->
  { model
  -- Keep the entries that don't have the given unique ID, because the entry
  -- that has it is the one we're removing
  | entries = List.filter (\entry -> entry.uid /= uid) model.entries
  }
```

**An Aside**

We can rewrite the anonymous function we pass to `List.filter` as follows:

```elm
(\entry -> entry.uid /= uid)
-->
(\entry -> uid /= entry.uid)
-->
(\entry -> (/=) uid entry.uid)
-->
(\entry -> ((/=) uid) entry.uid)
-->
(\entry -> entry.uid) >> ((/=) uid)
-->
.uid >> ((/=) uid)
```

- Learn about `>>`, i.e. function composition, [here](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Basics#>>).
- Learn more about record access [here](http://elm-lang.org/docs/records#access).

Hence, if you wanted, you could rewrite the filter like so:

```elm
RemoveEntry uid ->
  { model | entries = List.filter (.uid >> ((/=) uid)) model.entries }
```

But that's entirely up to you and what you find easier to read.

Anyway, we can now remove entries.

Compile and try it out in your browser.

## Show the button only when you hover over the entry

The button works but we don't want it visible at all times. We'd like the button to appear only when we hover over an entry.

It's actually quite easy to do with the following CSS:

```css
.visible-on-hover {
  visibility: hidden;
}

.hover-target:hover .visible-on-hover {
  visibility: visible;
}
```

And, here's how we set it up on our elements.

```elm
viewEntry { uid, description, completed } =
  div [ class "hover-target" ]
    [ input -- ...
    , span -- ...
    , button
        [ type_ "button"
        , class "ml-1 visible-on-hover"
        , Events.onClick (RemoveEntry uid)
        ]
        [ text "x" ]
    ]
```

Initially, the button is hidden since `visible-on-hover` applies the `visibility: hidden` rule. When we hover over the `hover-target` then the second rule `.hover-target:hover .visible-on-hover` takes priority and causes the button to appear.

Compile and try it out in your browser.

Congratulations! You've completed step 5.
