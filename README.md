# Sprocket

[![Package Version](https://img.shields.io/hexpm/v/sprocket)](https://hex.pm/packages/sprocket)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sprocket/)

Sprocket is a server-side framework that enables real-time experiences over a WebSocket
connection. It is heavily inspired by [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) and [React](https://github.com/facebook/react). The name "Sprocket" is derived from the
metaphor of a bicycle's cassette and chain. 

Similar to Phoenix LiveView, Sprocket renders an initial static HTML view as a "first paint" and then establishes a connection to the server over a WebSocket which facilitates receiving browser events and sending diff updates. These updates are patched into browser DOM using morphdom.

Similar to React, Sprocket supports functional components that accept props and render each time those props change. It also supports creating reducers for state management and using basic functions as event handlers. These event handlers can call external APIs or dispatch reducer state updates.

Under the hood, each reducer is a lightweight [Gleam Actor](https://hexdocs.pm/gleam_otp/0.1.3/gleam/otp/actor/) process (similar to a GenServer), and changes to the state result in a re-render of the view. 

This library is a collection of patterns and common functions that facilitate building declarative, functional
components that are composable and reusable. These components are then combined and used by parent component views.

This library is currently in its infancy and should currently be considered
a **proof of concept**. There is still a lot of work to be done, including building out all HTML
functions, adding support for more event types, introducing additional hooks, improving unit test
coverage, providing extensive documentation of modules and API, and optimizing performance. 

## Key Features

- Real-time web app framework over a WebSocket connection
- Renders initial HTML and patches updates to in-browser DOM state
- Supports functional components that react to prop changes
- Defines reducers for state management
- Uses lambda functions as event handlers for API calls and state updates
- Built on Gleam actors for efficient state management
- Encourages functional views and reusable, composable components

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

4. Open your web browser and visit `http://localhost:3000` to see the sample app.


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
