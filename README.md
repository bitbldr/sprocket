# Sprocket
A framework for building real-time server UI components and live views in [Gleam ✨](https://gleam.run/)

[![Package Version](https://img.shields.io/hexpm/v/sprocket)](https://hex.pm/packages/sprocket)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sprocket/)

[Demo Documentation](https://sprocket.live)

Heavily inspired by [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) and
[React](https://github.com/facebook/react). The name "sprocket" is loosely derived from the metaphor
of a bicycle's sprocket, cassette and chain.

An initial static view is rendered as HTML on the "first paint" which then establishes a connection to the server over a
WebSocket to facilitate sending browser events and receiving view update diffs. These updates are
patched into a client-side in-memory representation of the DOM and efficiently rendered to the
browser DOM. Declarative views are built using functional components that accept props and re-render
when state changes. Contextual hooks are used to manage state and effects, e.g.
`state`, `reducer` and `effect`.

Typed component interfaces snap together and are used to create higher-level views. Data flow is
"uni-directional" in that **State** always flows down into components as props and **Events**
bubble up through event handler functions (which are also passed in as props, e.g.
`on_some_event("Something happened")`). 

## Key Features

- Real-time server-side UI component framework
- Renders initial HTML and efficiently patches updates to the DOM using diffs sent over a persistent WebSocket connection
- Declarative and composable functional components that re-render when state changes
- Strong, static type system means fewer runtime crashes and easier maintenance
- Lightweight OTP processes make for a more efficient and scalable application
- Built on top of the venerable Erlang BEAM VM, which is renowned for high-concurrency and fault-tolerance

## Example

### Clock Component
```gleam
type Model {
  Model(time: Int, timezone: String)
}

type Msg {
  NoOp
  UpdateTime(Int)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> model
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

pub fn clock(ctx: Context, props) {
  let ClockProps(label) = props

  // Define a reducer to handle events and update the state
  use ctx, Model(time: time, ..), dispatch <- reducer(
    ctx,
    initial(),
    update,
  )

  // Example effect that runs whenever the `time` variable changes and has a cleanup function
  use ctx <- effect(
    ctx,
    fn() {
      let cancel =
        interval(
          1000,
          fn() { dispatch(UpdateTime(erlang.system_time(erlang.Second))) },
        )

      Some(fn() { cancel() })
    },
    [dep(time)],
  )

  let current_time = int.to_string(time)

  render(
    ctx,
    case label {
      Some(label) -> fragment([span([], [text(label)]), span([], [text(current_time)])])
      None -> text(current_time)
    },
  )
}
```

### Parent view
```gleam
pub type ExampleViewProps {
  ExampleViewProps
}

pub fn example_view(ctx: Context, _props: ExampleViewProps) {
  render(
    ctx,
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
  )
}

```

## Getting Started

To get started with Sprocket, follow the instructions below:

1. Clone the Sprocket starter repository:
```sh
git clone https://github.com/bitbldr/sprocket_starter.git
```

1. Install the required dependencies:
```sh
gleam deps download
yarn
```

1. Start the development server:
```sh
yarn run watch
```

1. Open your web browser and visit [http://localhost:3000](http://localhost:3000) to see the starter app.


## Installation

This package can be added to your Gleam project:

```sh
gleam add sprocket
```

For getting started with Sprocket, refer to the [Official Docs](https://sprocket.live).
Here you will find detailed examples and tutorials. These docs are
build with sprocket, which also make them an excellent reference implementation [github.com/bitbldr/sprocket_docs](https://github.com/bitbldr/sprocket_docs).


## API Documentation

API documentation can be found at <https://hexdocs.pm/sprocket>.


## Roadmap

Sprocket is still in its early stages and has a roadmap for future development. Here are some of the planned improvements:

- [x] Build out full set of base HTML functions for components
- [x] Expand the available hooks to enable more flexible component behavior
- [x] Add documentation to modules and simplify API
- [ ] Add support for additional event types to handle various user interactions
- [ ] Improve unit test coverage to ensure code quality and reliability
- [ ] Add support for web-based client components
- [ ] Investigate extending to support more than just web views, such as native desktop, iOS, and Android applications.

## Contributing

Contributions to Sprocket are welcome and encouraged! If you would like to contribute, please follow
the guidelines outlined in the
[CONTRIBUTING.md](https://github.com/bitbldr/sprocket/blob/master/CONTRIBUTING.md) file.

## License

Sprocket is released under the [MIT License](https://github.com/bitbldr/sprocket/blob/master/LICENSE.md).
