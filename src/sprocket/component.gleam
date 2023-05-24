import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/dynamic.{Dynamic}
import sprocket/html/attrs.{HtmlAttr}

pub type Element {
  Element(tag: String, attrs: List(HtmlAttr), children: List(Element))
  Component(c: fn(ComponentContext) -> List(Element))
  RawHtml(html: String)
}

pub fn raw(html: String) {
  RawHtml(html)
}

pub type ComponentContext {
  ComponentContext(fetch_or_create_reducer: fn(fn() -> Dynamic) -> Dynamic)
}

pub type State(model, msg) {
  State(m: model, d: Updater(msg))
}

type Reducer(model, msg) =
  fn(model, msg) -> model

pub type Updater(msg) =
  fn(msg) -> Nil

pub fn reducer(
  ctx: ComponentContext,
  initial: model,
  reducer: Reducer(model, msg),
) -> State(model, msg) {
  let ComponentContext(fetch_or_create_reducer: fetch_or_create_reducer) = ctx

  let reducer_init = fn() {
    let assert Ok(actor) = actor.start(initial, handle_message)

    dynamic.from(actor)
  }

  let actor =
    fetch_or_create_reducer(reducer_init)
    |> dynamic.unsafe_coerce

  let state = process.call(actor, StateReducer(_), 10)
  let dispatch = fn(msg) -> Nil {
    actor.send(actor, DispatchReducer(r: reducer, m: msg))
  }

  State(state, dispatch)
}

type ReducerOrGetter(model, msg) {
  StateReducer(reply_with: Subject(model))
  DispatchReducer(r: Reducer(model, msg), m: msg)
}

fn handle_message(
  message: ReducerOrGetter(model, msg),
  context: model,
) -> actor.Next(model) {
  case message {
    StateReducer(reply_with) -> {
      process.send(reply_with, context)
      actor.Continue(context)
    }
    DispatchReducer(r, m) -> {
      r(context, m)
      |> actor.Continue
    }
  }
}
