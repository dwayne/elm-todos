# Step 2

## Goal

To be able to type the description of a task into a text field and have the description appear in the browser's console when entered.

## Plan

1. Display a text field.
2. Keep track of the description.
3. Display the description.

## Display a text field

Edit `Todo.elm` to have the following content:

```elm
module Todo exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)

main =
  input
    [ type_ "text"
    , autofocus True
    , placeholder "What needs to be done?"
    ]
    []
```

Since we would be using many functions from the `Html` and `Html.Attributes` modules, I decided to make all of their functions available to the `Todo` module. Hence, instead of having to write `Html.input` or `Html.Attributes.type_`, which can get tedious, we can simply write `input` or `type_` respectively.

**N.B.** *It's not always wise to use `import M exposing (..)` as it can make it harder to track down where a given function is defined (especially in large files). You should use this feature sparingly and with caution since it can negatively affect the readability of your code.*

Compile `Todo.elm` and open `index.html` in your browser.

```sh
$ elm-make Todo.elm --output todo.js
$ xdg-open index.html
```

You would see a text field with the placeholder "What needs to be done?". The field would have focus and you'd be able to type anything you want into it. However, nothing would happen if you press ENTER.

## Keep track of the description

To keep track of the description we need to add an [onInput](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html-Events#onInput) event handler to the text field. The handler allows us to get access to the value that's entered in the text field.

Here's the type signature for `onInput`:

```elm
onInput : (String -> msg) -> Attribute msg
```

`onInput` takes one argument, a function. The function takes a `String`, which is the value that's entered in the text field. The function is used to tag whatever is currently in the text field.

To use `onInput` in the way we want we need to change our current setup. We need to restructure `Todo.elm` to make use of [The Elm Architecture](https://guide.elm-lang.org/architecture/).

In particular, we'd need a `Model`, an `update` function, a `view` function and to use [Html.beginnerProgram](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#beginnerProgram) to make it all work.

**Model**

The `Model` would be a record with one field that we'd use for keeping track of the description.

```elm
type alias Model =
  { description : String }

model : Model
model =
  { description = "" }
```

Initially, the description is empty.

**Update**

When the value in the text field changes, `onInput` tags the value which we refer to as a message. The Elm Runtime then sends the message to our `update` function for processing.

Firstly, we define a [union type](https://guide.elm-lang.org/types/union_types.html) for our messages.

```elm
type Msg
  = SetDescription String
```

Notice that `SetDescription` has the type `String -> Msg` which means it's a suitable argument for `onInput`.

Secondly, we write our `update` function to process the `SetDescription` message.

```elm
update : Msg -> Model -> Model
update msg model =
  case msg of
    SetDescription description ->
      { model | description = description }
```

It updates the model's description to the value we got from the text field.

**View**

We'd let the `view` function handle the rendering of our application from now on.

```elm
import Html.Events as Events
.
.

view : Model -> Html Msg
view { description } =
  input
    [ type_ "text"
    , autofocus True
    , placeholder "What needs to be done?"
    , value description
    , Events.onInput SetDescription
    ]
    []
```

Notice that we added two new attributes. The `onInput` event handler as promised and the `value` attribute.

The `onInput` event handler uses our `SetDescription` message to wrap the `event.target.value` whenever the value in the text field changes. The message then gets sent to our `update` function which updates our model with the new description.

We set the `value` attribute so that the text field displays the description that's in our model at all times. To see why this is necessary think of what would happen if our model's initial description was non-empty and we didn't set the `value` attribute.

Here are the changes you'd make to test it out.

```elm
model = { description = "Write a to-do list app" }
.
.

view { description } =
  input
    [ type_ "text"
    , autofocus True
    , placeholder "What needs to be done?"
    , Events.onInput SetDescription
    ]
    []
```

See below on how to change `main` to use `Html.beginnerProgram`. Then, compile with `elm-make Todo.elm --output todo.js --debug`, open `index.html` in your browser and use the debug panel, titled "Explore History", to see what's happening.

**main**

Change `main` to use [Html.beginnerProgram](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html#beginnerProgram).

```elm
main : Program Never Model Msg
main =
  Html.beginnerProgram
    { model = model
    , update = update
    , view = view
    }
```

This wires up everything in the correct way so that it all works as expected.

**N.B.** *If all of this is new to you then please take the time to read [The Elm Architecture](https://guide.elm-lang.org/architecture/) in its entirety.*

**Final version**

Here's the final correct version of `Todo.elm`.

```elm
module Todo exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events

main : Program Never Model Msg
main =
  Html.beginnerProgram
    { model = model
    , update = update
    , view = view
    }

-- MODEL

type alias Model =
  { description : String }

model : Model
model =
  { description = "" }

-- UPDATE

type Msg
  = SetDescription String

update : Msg -> Model -> Model
update msg model =
  case msg of
    SetDescription description ->
      { model | description = description }

-- VIEW

view : Model -> Html Msg
view { description } =
  input
    [ type_ "text"
    , autofocus True
    , placeholder "What needs to be done?"
    , value description
    , Events.onInput SetDescription
    ]
    []
```

Compile with `elm-make Todo.elm --output todo.js --debug`, open `index.html` in your browser and explore how we're keeping track of the description. Just type into the text field and use the debug panel titled "Explore History" to see the messages that get sent.

## Display the description

Currently, nothing happens when we press ENTER in the text field. Let's change that.

Wrap the text field in an `Html.form` and add an [onSubmit](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html-Events#onSubmit) handler.

```elm
view { description } =
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
```

Now, when we press ENTER in the text field the `AddEntry` message would be sent to the `update` function for processing.

Let's add the new message to our `Msg` type and handle it in our `update` function.

```elm
type Msg
  = SetDescription String
  | AddEntry

update : Msg -> Model -> Model
update msg model =
  case msg of
    .
    .

    AddEntry ->
      Debug.log model.description model
```

Compile and explore the changes in your browser. Type something into the text field, press ENTER and voila, the description appears in the console. To see it, open the console view in your browser's development tools.

We're almost done. Let's clear the text field after ENTER is pressed and let's not display empty strings in the console.

```elm
AddEntry ->
  let
    cleanDescription =
      String.trim model.description
  in
    if String.isEmpty cleanDescription then
      model
    else
      Debug.log cleanDescription { model | description = "" }
```

Compile again and explore.

**N.B.** *If you're following along with version control then this is a good point to commit your changes. In general, at the end of each step or between each part in a step it would be good to commit your changes.*

Congratulations! You've completed step 2.
