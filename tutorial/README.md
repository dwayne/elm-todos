# Elm Todos Tutorial

A step-by-step tutorial that teaches you how to build a to-do list application in [Elm](http://elm-lang.org/).

## Prerequisites

**Disclaimer:** *This tutorial is NOT intended for beginners to programming or web development.*

You should have a beginner to intermediate level of understanding of Elm and some experience with web development.

If not, then I'd recommend starting with one or more of the following resources.

**For Elm:**

- [An Introduction to Elm](https://guide.elm-lang.org/)
- [Beginning Elm](http://elmprogramming.com/)
- [Building Web Apps with Elm](https://pragmaticstudio.com/elm)
- [Elm Frontend Masters Course](https://frontendmasters.com/courses/elm/)
- [Elm in Action](https://www.manning.com/books/elm-in-action)

**For Programming:**

 - [How to Design Programs](http://www.htdp.org/)

**For Web Development:**

 - [Learn to Code HTML & CSS](https://learn.shayhowe.com/)
 - [Eloquent JavaScript](https://eloquentjavascript.net/)
 - [Google Developers Training - Web](https://developers.google.com/training/web/)

## Introduction

The purpose of the tutorial is to help you reinforce your Elm knowledge by showing you how to methodically build a complete application with Elm.

I've broken up the to-do list application into a manageable feature set that takes roughly 10 steps to build the entire thing.

For each step I explicitly state a goal that we need to accomplish to consider that step (and corresponding feature) complete. To achieve the goal I explicitly state the plan of attack we're going to take. In this way I indent for you to get a high-level understanding of how we're approaching the problems that the feature manifests.

Along the way I try my best to explain what the code does. And when appropriate, I also explain why a certain decision was made.

Here are the 10 steps:

1. [To display "Hello, Elm!" in a browser](./step-01.md).
2. [To be able to type the description of a task into a text field and have the description appear in the browser's console when entered](./step-02.md).
3. [To show the entered descriptions in a list, ordered from least recent to most recent](./step-03.md).
4. [To be able to mark entries as completed](./step-04.md).
5. [To be able to remove an entry](./step-05.md).
6. [To add a variety of useful features](./step-06.md).
7. [To be able to view a subset of the entries (all, active or completed)](./step-07.md).
8. [To be able to keep the visibility filter in sync with the URL in the address bar](./step-08.md).
9. [To be able to edit existing entries](./step-09.md).
10. [To be able to sync to `localStorage`](./step-10.md).

Here's some of what you can expect to learn by going through the all of the steps:

- A simply way to set up and get started with an Elm application.
- How to break a problem into manageable pieces and solve it incrementally.
- How to work with input fields (for e.g. text and check box).
- How to use lists.
- How to model your data.
- Using union types effectively.
- Knowing when to use [Html.Keyed](http://package.elm-lang.org/packages/elm-lang/html/2.0.0/Html-Keyed).
- How to use [elm-lang/navigation](http://package.elm-lang.org/packages/elm-lang/navigation/2.1.0/).
- How to focus a DOM element with [Dom.focus](http://package.elm-lang.org/packages/elm-lang/dom/1.1.1/Dom#focus) from [elm-lang/dom](http://package.elm-lang.org/packages/elm-lang/dom/1.1.1).
- How to write and use a custom event handler (see `onEsc` in [step 9](./step-09.md)).
- How to communicate via JavaScript with both ports and flags.
- How to encode an Elm value into a JavaScript value using [Json.Encode](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Json-Encode).
- How to decode a JavaScript value into an Elm value using [Json.Decode](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Json-Decode).

## Questions

If you have any questions or suggestions then please feel free to file an issue and I will get to it as soon as possible.
