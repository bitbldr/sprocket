import gleam/option.{Option}
import gleam/dynamic.{Dynamic}

pub type HookDependencies =
  List(Dynamic)

// helper function to create a dependency from a value
pub fn dep(dependency: a) -> Dynamic {
  dynamic.from(dependency)
}

pub type HookTrigger {
  OnUpdate
  WithDeps(deps: HookDependencies)
}

pub type EffectCleanup =
  Option(fn() -> Nil)

pub type EffectResult {
  EffectResult(cleanup: EffectCleanup, deps: Option(HookDependencies))
}

pub type CallbackResult {
  CallbackResult(callback: fn() -> Nil, deps: Option(HookDependencies))
}

pub type Hook {
  Callback(
    callback: fn() -> Nil,
    trigger: HookTrigger,
    prev: Option(CallbackResult),
  )
  Effect(
    effect: fn() -> EffectCleanup,
    trigger: HookTrigger,
    prev: Option(EffectResult),
  )
  Reducer(reducer: Dynamic)
}
