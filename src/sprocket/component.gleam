import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import sprocket/html/attribute.{Attribute}

pub type Element {
  Element(tag: String, attrs: List(Attribute), children: List(Element))
  Component(c: fn(ComponentContext) -> List(Element))
  RawHtml(html: String)
}

pub fn raw(html: String) {
  RawHtml(html)
}

pub type Effect {
  Effect(deps: List(Dynamic))
  NewEffect(deps: List(Dynamic))
}

pub type ComponentContext {
  ComponentContext(
    fetch_or_create_reducer: fn(fn() -> Dynamic) -> Dynamic,
    render_update: fn() -> Nil,
    get_or_create_effect: fn(Effect) -> Effect,
  )
}

pub type Updater(msg) =
  fn(msg) -> Nil

pub type State(model, msg) {
  State(m: model, d: Updater(msg))
}

type Reducer(model, msg) =
  fn(model, msg) -> model

type StateOrDispatchReducer(model, msg) {
  StateReducer(reply_with: Subject(model))
  DispatchReducer(r: Reducer(model, msg), m: msg)
}

pub fn reducer(
  ctx: ComponentContext,
  initial: model,
  reducer: Reducer(model, msg),
) -> State(model, msg) {
  let ComponentContext(
    fetch_or_create_reducer: fetch_or_create_reducer,
    render_update: render_update,
    ..,
  ) = ctx

  let reducer_init = fn() {
    let assert Ok(actor) =
      actor.start(
        initial,
        fn(message: StateOrDispatchReducer(model, msg), context: model) -> actor.Next(
          model,
        ) {
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
        },
      )

    dynamic.from(actor)
  }

  let actor =
    fetch_or_create_reducer(reducer_init)
    |> dynamic.unsafe_coerce

  let state = process.call(actor, StateReducer(_), 10)
  let dispatch = fn(msg) -> Nil {
    actor.send(actor, DispatchReducer(r: reducer, m: msg))
    render_update()
  }

  State(state, dispatch)
}

// create useEffect function that takes a function and a list of dependencies
pub fn effect(
  ctx: ComponentContext,
  effect_fn: fn() -> Nil,
  dependencies: List(Dynamic),
) {
  let ComponentContext(
    render_update: render_update,
    get_or_create_effect: get_or_create_effect,
    ..,
  ) = ctx

  case get_or_create_effect(Effect(deps: dependencies)) {
    NewEffect(_) -> {
      // TODO: we might need to push this effect_fn onto a stack and run
      // after the current render cycle has completed
      effect_fn()
      render_update()
    }
    Effect(deps) -> {
      let deps_changed = deps != dependencies

      case deps_changed {
        True -> {
          effect_fn()
          render_update()
        }
        _ -> Nil
      }
    }
  }
}
