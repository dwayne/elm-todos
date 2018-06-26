# Step 7

## Goal

To be able to view a subset of the entries (all, active or completed).

## Plan

1. Add a visibility filter and only show the entries that match it.
2. Fix a bug where the incorrect DOM node is being reused.
3. Add a way to change the visibility filter.

## Add a visibility filter and only show the entries that match it

We want to be able to show the entries that match a given visibility filter. We'd have three types of visibility filters:

1. One that shows all the entries, the default.
2. One that shows the incomplete/active entries.
3. And, one that shows the completed entries.

We'd model it using a [union type](http://elm-lang.org/docs/syntax#union-types):

```elm
type Visibility
  = All
  | Active
  | Completed
```

Let's keep track of the current visibility in the model and set its default value to `All`.

```elm
type alias Model =
  { uid : Int
  , description : String
  , visible : Visibility
  , entries : List Entry
  }

.
.

model : Model
model =
  { uid = 0
  , description = ""
  , visible = All
  , entries = []
  }
```

Then, we'd update the view to show the visible entries based on the filter that's applied.

```elm
view { description, visible, entries } =
  div []
    [ viewPrompt description
    , viewBody visible entries
    ]

viewBody : Visibility -> List Entry -> Html Msg
viewBody visible entries =
  if List.isEmpty entries then
    -- ...
  else
    div []
      [ -- ...
      , ul []
          <| List.map (\entry -> li [] [ viewEntry entry ]) (keep visible entries)
      , -- ...
      ]

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
```

Compile and try it in your browser.

By default you'd see all the entries you enter. However, to test out the other values of `visible` you'd need to change the value in the source code, recompile and refresh the page.

## Fix a bug where the incorrect DOM node is being reused

If you've played around with the previous changes then you've probably seen the bug. Here's how to reproduce it:

1. Set `visible` to `Active`.
2. Enter a few entries.
3. Mark the top entry as completed.

You'd notice that the entry you marked is now not displayed (as it should) but the entry that was below is displayed in its place with the check box checked. This is a bug since the check box should be unchecked.

To fix the problem we need to use [Html.Keyed.ul](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html-Keyed#ul) instead of [Html.ul](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#ul).

```elm
import Html.Keyed as Keyed

.
.

viewBody visible entries =
  if List.isEmpty entries then
    -- ...
  else
    div []
      [ -- ...
      , Keyed.ul []
          <| List.map
              (\entry -> (toString entry.uid, li [] [ viewEntry entry ]))
              (keep visible entries)
      , -- ...
      ]
```

Compile and try to reproduce the bug. You'd see that we don't have that problem any more.

**N.B.** *The `Html.Keyed` module doesn't mention that keyed nodes can be used to fix this kind of bug. It only says that "A keyed node helps optimize cases where children are getting added, moved, removed, etc.". I thought using keyed nodes would help only because of my experience fixing a similar bug in a [React](https://reactjs.org/) component. There was some discussion about this issue in the [Elm Google Group](https://groups.google.com/d/msg/elm-dev/V0HaGgjQHW4/eQxj-kDOBAAJ) but nothing seems to have come of it since there is no mention that stateful DOM nodes could be reused in the wrong places. Maybe there is another way to fix the bug that I don't know about.*

## Add a way to change the visibility filter

Obviously having to change the source code, recompile and refresh the browser every time we need to change the visibility filter isn't a good user experience. So, let's add a way for our users to change the visibility filter.

We'd add three links, labeled "All", "Active" and "Completed", right above the "Clear completed" button. When one of the links is clicked we would have it result in a change to the visibility filter. And, everything else would continue to work as normal.

Here are the changes we need to make:

```elm
type Msg
   = SetDescription String
   | SetVisible Visibility
   | -- ...

update msg model =
  case msg of
    SetDescription description ->
      -- ...

    SetVisible visible ->
      { model | visible = visible }

    -- ...

viewBody visible entries =
  if List.isEmpty entries then
    -- ...
  else
    div []
      [ -- ...
      , viewVisibilityFilters visible
      , button -- ...
      ]

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
    a [ href url, Events.onClick (SetVisible current) ] [ text name ]
```

Compile and try it out in your browser.

Congratulations! You've completed step 7.
