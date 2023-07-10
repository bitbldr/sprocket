# Sprocket
Persistent Reactive Sockets

[![Package Version](https://img.shields.io/hexpm/v/sprocket)](https://hex.pm/packages/sprocket)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sprocket/)

A framework for building real-time server components in [Gleam ✨](https://gleam.run/). Heavily
inspired by [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view),
[React](https://github.com/facebook/react) and [Elm](https://github.com/elm). The name "sprocket"
is loosely derived from the metaphor of a bicycle's sprocket, cassette and chain.

Sprocket combines the best of LiveView server-side productivity and scalability, React components
and Elm functional state management patterns all implemented in Gleam, a type-safe
language built on the venerable BEAM (Erlang Virtual Machine).

Similar to LiveView, an initial static view is
rendered as HTML on the "first paint" which then establishes a connection to the server over a
WebSocket to facilitate sending browser events and receiving view update diffs. These update patches are
rendered to browser DOM using morphdom. Like React, declarative views are built using functional
components that accept props and render each time those props change. Finally, inspired by Elm,
strongly-typed models and message structs are used for state management via reducers.

Under the hood, a reducer is a lightweight [Gleam
Actor](https://hexdocs.pm/gleam_otp/0.1.3/gleam/otp/actor/) OTP process (i.e. gen_server) and
changes to the state result in a re-render of the view. 

This library is a collection of patterns and common functions that facilitate building declarative
views from composable functional components. Components are used to create higher-level views, like Lego blocks.
Data flows down into components in the form of props and out of components in the form of events.
It's useful to think of the data flow as "uni-directional" in that **State** always flows down via
props and **Events** always bubbles up using event handler functions (passed in as props, e.g. `onSomeEvent("Something happened")`).

This library is currently in a **proof of concept** state and should be considered highly unstable.
There is still a lot of work to be done, including building out all HTML
functions, adding support for more event types, introducing additional hooks, improving unit test
coverage, providing extensive documentation of modules and API, and optimizing performance. 

## Key Features

- Real-time, scalable, server-side component framework
- Renders initial HTML and efficiently patches update diffs using a WebSocket connection
- Declarative views using functional components that rerender on prop changes
- Strongly-typed functional reducers for state management
- Built on lightweight OTP processes for composable & scalable state management
- Encourages declarative and composable views

## Example

### Clock Component
```gleam
type Model {
  Model(time: Int, timezone: String)
}

type Msg {
  UpdateTime(Int)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UpdateTime(time) -> {
      Model(..model, time: time)
    }
  }
}

fn initial() -> Model {
  Model(time: erlang.system_time(erlang.Second), timezone: "UTC")
}

pub type ClockProps {
  ClockProps(label: Option(String))
}

pub fn clock(socket: Socket, props) {
  let ClockProps(label) = props

  // Define a reducer to handle events and update the state
  use socket, State(Model(time: time, ..), dispatch) <- reducer(
    socket,
    initial(),
    update,
  )

  // Example effect that runs whenever the `time` variable changes and has a cleanup function
  use socket <- effect(
    socket,
    fn() {
      let cancel =
        interval(
          1000,
          fn() { dispatch(UpdateTime(erlang.system_time(erlang.Second))) },
        )

      Some(fn() { cancel() })
    },
    WithDependencies([dynamic.from(time)]),
  )

  let current_time = int.to_string(time)

  render(
    socket,
    case label {
      Some(label) -> [span([], [text(label)]), span([], [text(current_time)])]
      None -> [text(current_time)]
    },
  )
}
```

### Parent composable view
```gleam
pub type ExampleViewProps {
  ExampleViewProps
}

pub fn example_view(socket: Socket, _props: ExampleViewProps) {
  render(
    socket,
    [
      html(
        [lang("en")],
        [
          head([], [link([rel("stylesheet"), href("/app.css")])]),
          body(
            [class("bg-white dark:bg-gray-900 dark:text-white p-4")],
            [
              component(
                clock,
                ClockProps(label: Some("The current time is: ")),
              ),
            ],
          ),
        ],
      ),
    ],
  )
}

```

## Getting Started

To get started with Sprocket, follow the instructions below:

1. Clone the Sprocket repository:
```
git clone https://github.com/eliknebel/sprocket.git
```

2. Install the required dependencies:
```
gleam deps download
yarn
```

3. Start the development server:
```
yarn run watch
```

4. Open your web browser and visit `http://localhost:3000` to see the docs sample app.


## TODO: Installation

If available on Hex this package can be added to your Gleam project:

```sh
gleam add sprocket
```

and its documentation can be found at <https://hexdocs.pm/sprocket>.


## TODO: Documentation

Documentation for Sprocket can be found in the [docs](/docs) directory of this repository. It provides detailed information on how to use Sprocket, including module descriptions, API references, and examples.

## Roadmap

Sprocket is still in its early stages and has a roadmap for future development. Here are some of the planned improvements:

- Build out full set of base HTML functions for components (or investigate using an [existing library](https://github.com/nakaixo/nakai))
- Add support for additional event types to handle various user interactions
- Expand the available hooks to enable more flexible component behavior
- Convert client TypeScript to gleam
- Improve unit test coverage to ensure code quality and reliability
- Provide extensive documentation of modules and API for easier adoption
- Optimize performance to enhance responsiveness and scalability
- Investigate extending to support more than just web views, such as native desktop, iOS, and Android applications.

## Contributing

Contributions to Sprocket are welcome and encouraged! If you would like to contribute, please follow the guidelines outlined in the [CONTRIBUTING.md](/CONTRIBUTING.md) file.

## License

Sprocket is released under the [MIT License](/LICENSE).
