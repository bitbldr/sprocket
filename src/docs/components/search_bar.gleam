import sprocket/socket.{Socket}
import sprocket/component.{render}
import sprocket/hooks.{WithDeps, dep}
import sprocket/hooks/callback.{callback}
import sprocket/identifiable_callback.{CallbackWithValueFn}
import sprocket/hooks/reducer.{State, reducer}
import sprocket/html.{input}
import sprocket/html/attribute.{class, input_type, on_input, placeholder, value}

type Model {
  Model(query: String)
}

type Msg {
  NoOp
  SetQuery(query: String)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> model
    SetQuery(query) -> Model(query: query)
  }
}

fn initial() -> Model {
  Model(query: "")
}

pub type SearchBarProps {
  SearchBarProps(on_search: fn(String) -> Nil)
}

pub fn search_bar(socket: Socket, props) {
  let SearchBarProps(on_search: on_search) = props

  // Define a reducer to handle events and update the state
  use socket, State(Model(query: query), dispatch) <- reducer(
    socket,
    initial(),
    update,
  )

  use socket, on_input_query <- callback(
    socket,
    CallbackWithValueFn(fn(value: String) {
      on_search(value)
      dispatch(SetQuery(value))
    }),
    WithDeps([dep(on_search)]),
  )

  render(
    socket,
    [
      input([
        input_type("text"),
        class(
          "m-2 pl-2 pr-4 py-1 rounded bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-600 focus:outline-none focus:border-blue-500",
        ),
        placeholder("Search..."),
        value(query),
        on_input(on_input_query),
      ]),
    ],
  )
}
