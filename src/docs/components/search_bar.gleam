import gleam/option.{None, Option, Some}
import sprocket/socket.{Socket}
import sprocket/component.{render}
import sprocket/hooks/reducer.{State, reducer}
import sprocket/html.{div, input, text}
import sprocket/html/attribute.{class, input_type, placeholder, value}

type Model {
  Model(query: Option(String))
}

type Msg {
  NoOp
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> model
  }
}

fn initial() -> Model {
  Model(query: None)
}

pub type SearchBarProps {
  SearchBarProps(on_search: fn(String) -> Nil)
}

pub fn search_bar(socket: Socket, _props) {
  // let SearchBarProps(on_search: on_search) = props

  // Define a reducer to handle events and update the state
  use socket, State(Model(query: query), _dispatch) <- reducer(
    socket,
    initial(),
    update,
  )

  render(
    socket,
    [
      input([
        input_type("text"),
        class(
          "m-2 px-2 py-1 rounded bg-white border border-gray-200 text-gray-600",
        ),
        placeholder("Search..."),
        value(option.unwrap(query, "")),
      ]),
    ],
  )
}
