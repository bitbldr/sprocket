import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/dynamic.{Dynamic}
import sprocket/html/attribute.{Attribute}

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
  OnUpdate
  WithDependencies(deps: EffectDependencies)
}

pub type Hook {
  Effect(effect_fn: fn() -> EffectCleanup, trigger: EffectTrigger)
}

pub type ComponentContext {
  ComponentContext(
    fetch_or_create_reducer: fn(fn() -> Dynamic) -> Dynamic,
    request_live_update: fn() -> Nil,
    push_hook: fn(Hook) -> Nil,
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
    request_live_update: request_live_update,
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
    request_live_update()
  }

  State(state, dispatch)
}

pub fn effect(
  ctx: ComponentContext,
  effect_fn: fn() -> EffectCleanup,
  trigger: EffectTrigger,
) -> Nil {
  let ComponentContext(push_hook: push_hook, ..) = ctx

  push_hook(Effect(effect_fn, trigger))
}
