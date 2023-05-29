import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/dynamic.{Dynamic}
import gleam/option.{Option, Some}
import sprocket/html/attribute.{Attribute}
import sprocket/logger

pub type Element {
  Element(tag: String, attrs: List(Attribute), children: List(Element))
  Component(c: fn(ComponentContext) -> List(Element))
  RawHtml(html: String)
}

pub fn raw(html: String) {
  RawHtml(html)
}

pub type EffectCleanup {
  EffectCleanup(fn() -> Nil)
  NoCleanup
}

pub type EffectDependencies =
  List(Dynamic)

pub type EffectTrigger {
  Always
  WhenDependenciesChange(deps: EffectDependencies)
}

pub type Effect {
  EffectSpec(effect_fn: fn() -> EffectCleanup, deps: EffectDependencies)
  Effect(
    id: String,
    effect_fn: fn() -> EffectCleanup,
    deps: EffectDependencies,
    cleanup: Option(EffectCleanup),
  )
  EffectCreated(id: String, effect_fn: fn() -> EffectCleanup)
}

pub type ComponentContext {
  ComponentContext(
    fetch_or_create_reducer: fn(fn() -> Dynamic) -> Dynamic,
    render_update: fn() -> Nil,
    get_or_create_effect: fn(Effect) -> Effect,
    update_effect: fn(Effect) -> Nil,
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
  effect_fn: fn() -> EffectCleanup,
  dependencies: EffectDependencies,
) -> Nil {
  let ComponentContext(
    render_update: render_update,
    get_or_create_effect: get_or_create_effect,
    update_effect: update_effect,
    ..,
  ) = ctx

  case get_or_create_effect(EffectSpec(effect_fn, dependencies)) {
    EffectCreated(id, effect_fn) -> {
      // TODO: we might need to push this effect_fn onto a stack and run
      // after the current render cycle has completed
      let cleanup = effect_fn()
      update_effect(Effect(id, effect_fn, dependencies, Some(cleanup)))
      render_update()
    }
    Effect(id, _prev_effect_fn, prev_deps, prev_cleanup) -> {
      case prev_deps != dependencies {
        True -> {
          case prev_cleanup {
            Some(EffectCleanup(cleanup)) -> cleanup()
            _ -> Nil
          }
          let cleanup = effect_fn()
          update_effect(Effect(id, effect_fn, dependencies, Some(cleanup)))
          render_update()
        }
        _ -> Nil
      }
    }
    e -> {
      logger.error("effect not created or found")

      Nil
    }
  }
}
