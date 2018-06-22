# Step 3

## Goal

To show the entered descriptions in a list, ordered from least recent to most recent.

## Plan

1. Keep track of a list of descriptions.
2. Append the entered description to the list of descriptions.
3. Show the list of descriptions.

## Keep track of a list of descriptions

Update the model to store a list of descriptions. We'd call the new field, `entries`.

```elm
type alias Model =
  { description : String
  , entries : List String
  }

model : Model
model =
  { description = ""
  , entries = []
  }
```

## Append the entered description to the list of descriptions

Recall that when we enter a description the `AddEntry` message gets sent to our `update` function. Currently, our `update` function simply logs the description in our browser's console. Let's change that.

```elm
AddEntry ->
  let
    cleanDescription =
      String.trim model.description
  in
    if String.isEmpty cleanDescription then
      model
    else
      { model
      | description = ""
      , entries = model.entries ++ [ cleanDescription ]
      }
```

The key change is `entries = model.entries ++ [ cleanDescription ]`, i.e. we update `entries` by appending the new description to the previous list of descriptions.

**N.B.** *In the interests of [KISS](https://en.wikipedia.org/wiki/KISS_principle) and avoiding premature optimization we use a list even though it takes O(n) time to append to them.*

## Show the list of descriptions

Finally, we update our view to show the list of descriptions.

```elm
view { description, entries } =
  div []
    [ Html.form [ Events.onSubmit AddEntry ]
        [ input
            [ type_ "text"
            , autofocus True
            , placeholder "What needs to be done?"
            , value description
            , Events.onInput SetDescription
            ]
            []
        ]
    , ul [] (List.map (\description -> li [] [ text description ]) entries)
    ]
```

We show the list of descriptions in an unordered list, [ul](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/ul).

Suppose,

```elm
entries = [ "a", "b", "c" ]
```

Then,

```elm
List.map (\description -> li [] [ text description ]) entries
-->
List.map (\description -> li [] [ text description ]) [ "a", "b", "c" ]
-->
[ (\description -> li [] [ text description ]) "a"
, (\description -> li [] [ text description ]) "b"
, (\description -> li [] [ text description ]) "c"
]
-->
[ li [] [ text "a" ]
, li [] [ text "b" ]
, li [] [ text "c" ]
]
```

Compile `Todo.elm`, open `index.html` and explore the changes.

```sh
$ elm-make Todo.elm --output todo.js --debug
$ xdg-open index.html
```

Make sure you understand how it's working before proceeding to the next step.

Congratulations! You've completed step 3.
