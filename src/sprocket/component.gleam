import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
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
  OnMount
  WithDependencies(deps: EffectDependencies)
}

pub type Effect {
  EffectSpec(effect_fn: fn() -> EffectCleanup, trigger: EffectTrigger)
  Effect(
    id: String,
    effect_fn: fn() -> EffectCleanup,
    trigger: EffectTrigger,
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

fn run_effect(
  id,
  effect_fn,
  trigger,
  prev_cleanup,
  update_effect,
  render_update,
) {
  case prev_cleanup {
    Some(EffectCleanup(cleanup)) -> cleanup()
    _ -> Nil
  }
  let cleanup = effect_fn()
  update_effect(Effect(id, effect_fn, trigger, Some(cleanup)))
  render_update()
}

// create useEffect function that takes a function and a list of dependencies
pub fn effect(
  ctx: ComponentContext,
  effect_fn: fn() -> EffectCleanup,
  trigger: EffectTrigger,
) -> Nil {
  let ComponentContext(
    render_update: render_update,
    get_or_create_effect: get_or_create_effect,
    update_effect: update_effect,
    ..,
  ) = ctx

  case get_or_create_effect(EffectSpec(effect_fn, trigger)) {
    EffectCreated(id, effect_fn) -> {
      // TODO: we might need to push this effect_fn onto a stack and run
      // after the current render cycle has completed
      case trigger {
        Always | OnMount | WithDependencies(_) ->
          run_effect(id, effect_fn, trigger, None, update_effect, render_update)
        _ -> Nil
      }
    }
    Effect(id, _prev_effect_fn, prev_trigger, prev_cleanup) -> {
      case trigger, prev_trigger {
        Always, _ ->
          run_effect(
            id,
            effect_fn,
            trigger,
            prev_cleanup,
            update_effect,
            render_update,
          )
        WithDependencies(deps), WithDependencies(prev_deps) if deps != prev_deps ->
          run_effect(
            id,
            effect_fn,
            trigger,
            prev_cleanup,
            update_effect,
            render_update,
          )
        _, _ -> Nil
      }
    }
    e -> {
      logger.error("effect not created or found")

      Nil
    }
  }
}
