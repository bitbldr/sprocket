import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/hooks.{WithDeps, dep}
import sprocket/hooks/callback.{callback}
import sprocket/internal/identifiable_callback.{CallbackWithValueFn}
import sprocket/hooks/reducer.{reducer}
import sprocket/html.{input}
import sprocket/html/attributes.{class,
  input_type, on_input, placeholder, value}

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

pub fn search_bar(ctx: Context, props) {
  let SearchBarProps(on_search: on_search) = props

  // Define a reducer to handle events and update the state
  use ctx, Model(query: query), dispatch <- reducer(ctx, initial(), update)

  use ctx, on_input_query <- callback(
    ctx,
    CallbackWithValueFn(fn(value: String) {
      on_search(value)
      dispatch(SetQuery(value))
    }),
    WithDeps([dep(on_search)]),
  )

  render(
    ctx,
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
