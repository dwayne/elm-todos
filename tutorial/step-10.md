# Step 10

## Goal

To be able to sync to `localStorage`.

## Plan

1. Save the model to `localStorage` when it changes.
2. Load the saved state from `localStorage` and display it in the console.
3. Load the saved state from `localStorage` and use it as the initial model.

# Save the model to `localStorage` when it changes

Every time our model changes we want to save it to [localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage).

A simple way to get at the updated model is to wrap our existing `update` function.

```elm
updateAndSave : Msg -> Model -> (Model, Cmd Msg)
updateAndSave msg model =
  let
    (nextModel, cmd) =
      update msg model
  in
    nextModel ! [ cmd, save (encodeModel nextModel) ]
```

We pass the `msg` and `model` to the `update` function. It returns the updated model `nextModel` and a command `cmd`. We simply return `nextModel` as is and batch `cmd` with a new command, which we'd write, that causes the updated model to be saved to `localStorage`.

Batching commands is how we get the Elm runtime to perform multiple commands. Recall that `nextModel ! [ cmd, save (encodeModel nextModel) ]` is just a shortcut way of writing `(nextModel, Cmd.batch [ cmd, save (encodeModel nextModel) ])`. Learn more about the command API [here](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Platform-Cmd).

To use `updateAndSave` we pass it to the `update` field of the second argument given to `Navigation.program`.

```elm
main =
  Navigation.program NewLocation
    { init = init
    , update = updateAndSave
    , view = view
    , subscriptions = always Sub.none
    }
```

**`save` and Ports**

To access `localStorage` we'd be using JavaScript. The way we'd have to communicate with the JavaScript in this instance would be through a port.

Evan suggests that we think of a port like a hole in the side of our Elm program where we can send values in and out. Learn more [here](https://guide.elm-lang.org/interop/javascript.html#ports).

Since we'd be sending values out to JavaScript our port would be classified as an outgoing port (as opposed to an incoming port).

```elm
-- 1. We need to add the port keyword whenever a module uses one or more ports.
port module Todo exposing (main)

-- 2. This is needed because our port takes a JavaScript value as its first argument.
import Json.Encode as Encode

-- 3. A port for saving our model to localStorage.
port save : Encode.Value -> Cmd msg
```

Here's how to think of the `save` port. It takes our model encoded as a JavaScript value and sends it off to JavaScript land for our JavaScript code to deal with it.

And here's how our JavaScript code deals with it.

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <!-- ... -->
  </head>
  <body>
    <script src="todo.js"></script>
    <script>
      var key = 'elm-todos-state';
      var app = Elm.Todo.fullscreen();
      app.ports.save.subscribe(function (modelToSave) {
        localStorage.setItem(key, JSON.stringify(modelToSave));
      });
    </script>
  </body>
</html>
```

When we call `Elm.Todo.fullscreen()` an object is returned with a `ports` attribute containing all our ports (i.e. both incoming and outgoing). Since `save` is an outgoing port it has a `subscribe` function attribute. The `subscribe` function takes a callback with an [arity](https://en.wikipedia.org/wiki/Arity) of one whose type is derived from the type of the argument given to the corresponding port. In this case, it's value would be whatever JavaScript value we decide to use to encode our model.

If we encode our model as a `String` then `modelToSave` would be a `String`. If we encode our model as a JavaScript object then `modelToSave` would be a JavaScript object.

We'd be encoding our model as a JavaScript object.

**Why do we have to manually encode our `Model`?**

If our `Model` didn't make use of the custom union types `Mode` and `Visibility` then we would have been able to get away with defining our `save` port in the following way:

```elm
port save : Model -> Cmd msg
```

And, Elm would have been able to automatically convert our model to a JavaScript value. However, as it stands, this isn't possible with our `Model` type.

**`encodeModel` and `Json.Encode`**

Suppose we have the following model:

```elm
model =
  { uid = 2
  , description = ""
  , mode = Edit 0 "Write a to-do list app"
  , visible = All
  , entries =
      [ { uid = 0, description = "Write a to-do list application", completed = True }
      , { uid = 1, description = "Write a tutorial", completed = False }
      ]
  }
```

Then, we want to write a function called `encodeModel` that would return something equivalent to the following JavaScript object:

```js
{
  uid: 2,
  description: "",
  mode: { ctor: "Edit", 0: 0, 1: "Write a to-do list app" },
  visible: "all",
  entries: [
    { uid: 0, description: "Write a to-do list application", completed: true },
    { uid: 1, description: "Write a tutorial", completed: false }
  ]
}
```

Here's the implementation that does it.

```elm
-- ENCODERS

encodeModel : Model -> Encode.Value
encodeModel { uid, description, mode, visible, entries } =
  Encode.object
    [ ("uid", Encode.int uid)
    , ("description", Encode.string description)
    , ("mode", encodeMode mode)
    , ("visible", encodeVisibility visible)
    , ("entries", Encode.list (List.map encodeEntry entries))
    ]

encodeMode : Mode -> Encode.Value
encodeMode mode =
  case mode of
    Normal ->
      Encode.object [ ("ctor", Encode.string "Normal") ]

    Edit uid description ->
      Encode.object
        [ ("ctor", Encode.string "Edit")
        , ("0", Encode.int uid)
        , ("1", Encode.string description)
        ]

encodeVisibility : Visibility -> Encode.Value
encodeVisibility visible =
  case visible of
    All ->
      Encode.string "all"

    Active ->
      Encode.string "active"

    Completed ->
      Encode.string "completed"

encodeEntry : Entry -> Encode.Value
encodeEntry { uid, description, completed } =
  Encode.object
    [ ("uid", Encode.int uid)
    , ("description", Encode.string description)
    , ("completed", Encode.bool completed)
    ]
```

I suggest that you read the code while following along with the `Json.Encode` API documentation which you can find [here](package.elm-lang.org/packages/elm-lang/core/5.1.1/Json-Encode).

**TODO:** *Explain how `encodeModel` works in more detail.*

Compile and try it out in your browser.

Make sure you understand how it all works by going through a couple made up examples on your own.

# Load the saved state from `localStorage` and display it in the console

Now that we're able to save the state of our model to `localStorage` we want our application to try to load any saved state as the initial value of our model.

In this part, we'd load the saved state and display it in the console. And, then in the next part we'd use the saved state to populate our model when the application loads for the first time.

Here's the JavaScript we need to add to get our saved state out of `localStorage` and back into the Elm program.

```js
var state = localStorage.getItem(key);
var savedModel = state ? JSON.parse(state) : null;
var app = Elm.Todo.fullscreen(savedModel);
```

`state` would either be a `String` or `null`. If parsing the `String` succeeds then `savedModel` would be a JavaScript value of the kind we saved in the previous part. Otherwise, `savedModel` would be `null`.

Either way we pass it along as a flag to our Elm program via `Elm.Todo.fullscreen(savedModel)`.

By the way, the use of [flags](https://guide.elm-lang.org/interop/javascript.html#flags) is another way we can communicate between JavaScript and Elm (you may have thought we'd use an incoming port but that's not necessary for our use case).

Back in `Todo.elm` we need to make a couple changes for Elm to be able to work with the data we sent it through the flags.

Firstly, we need to define the type of flags values our application accepts.

```elm
type alias Flags =
  Maybe Encode.Value
```

It's `Maybe Encode.Value` because we either send `null` (which would be represented as `Nothing`) or a JavaScript value (which would be represented as `Just encodedModel`).

Secondly, we need to change from using `Navigation.program` to [Navigation.programWithFlags](http://package.elm-lang.org/packages/elm-lang/navigation/2.1.0/Navigation#programWithFlags).

```elm
main : Program Flags Model Msg
main =
  Navigation.programWithFlags NewLocation
    { init = init
    , update = updateAndSave
    , view = view
    , subscriptions = always Sub.none
    }
```

And finally, we need to update the `init` function since it now receives a value of type `Flags` as its first argument. For now we'd just log it out to the console.

```elm
init : Flags -> Navigation.Location -> (Model, Cmd Msg)
init savedModel location =
  Debug.log (toString savedModel)
    { uid = 0
    , description = ""
    , mode = Normal
    , visible = toVisibility location
    , entries = []
    } ! []
```

Compile and try it out in your browser.

Open the console to see what was saved in `localStorage` from your previous use of the application.

All we need to do now is to convert that JavaScript value back into a value of type `Model` and use that as our initial model.

# Load the saved state from `localStorage` and use it as the initial model

```elm
import Json.Decode as Decode exposing (Decoder)

init savedModel location =
  let
    -- Determine visible's value based on what's in the URL rather than what
    -- was saved.
    visible =
      toVisibility location

    initModel =
      { uid = 0
      , description = ""
      , mode = Normal
      , visible = visible
      , entries = []
      }
  in
    case savedModel of
      Nothing ->
        -- Either this is the first time ever using the application or
        -- the saved data wasn't parsed (with JSON.parse) successfully.
        initModel ! []

      Just value ->
        -- We have the saved data in value.
        -- 1. Decode it.
        -- 2a. If it decodes successfully then use it as the initial model.
        -- 2b. Otherwise, we failed to decode it so we log the error and just
        --     use initModel as the initial model.
        case Decode.decodeValue modelDecoder value of
          Ok model ->
            { model | visible = visible } ! []

          Err e ->
            (Debug.log ("Unable to restore the saved model: " ++ e) initModel) ! []
```

Here's the [documentation](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Json-Decode#decodeValue) for `Decode.decodeValue`.

The last thing we need to do is write the `modelDecoder` function. In short, `modelDecoder` does the inverse of what `encodeModel` does.

```elm
-- DECODERS

modelDecoder : Decoder Model
modelDecoder =
  Decode.map5 Model
    (Decode.field "uid" Decode.int)
    (Decode.field "description" Decode.string)
    (Decode.field "mode" modeDecoder)
    (Decode.field "visible" visibilityDecoder)
    (Decode.field "entries" (Decode.list entryDecoder))

modeDecoder : Decoder Mode
modeDecoder =
  Decode.field "ctor" Decode.string
    |> Decode.andThen
        (\s ->
          case s of
            "Normal" ->
              Decode.succeed Normal

            "Edit" ->
              Decode.map2 Edit
                (Decode.field "0" Decode.int)
                (Decode.field "1" Decode.string)

            _ ->
              Decode.fail ("Unknown data constructor for mode: " ++ s)
        )

visibilityDecoder : Decoder Visibility
visibilityDecoder =
  Decode.string
    |> Decode.andThen
        (\s ->
          case s of
            "all" ->
              Decode.succeed All

            "active" ->
              Decode.succeed Active

            "completed" ->
              Decode.succeed Completed

            _ ->
              Decode.fail ("Unknown visibility: " ++ s)
        )

entryDecoder : Decoder Entry
entryDecoder =
  Decode.map3 Entry
    (Decode.field "uid" Decode.int)
    (Decode.field "description" Decode.string)
    (Decode.field "completed" Decode.bool)
```

**TODO:** *Explain `modelDecoder` in more detail.*

Compile and try it out in your browser.

Congratulations! You've completed step 10 and reached the end of the tutorial.
