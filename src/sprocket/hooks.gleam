import gleam/option.{Option}
import gleam/dynamic.{Dynamic}

pub type HookDependencies =
  List(Dynamic)

pub type HookTrigger {
  OnUpdate
  WithDeps(deps: HookDependencies)
}

pub type HookCleanup =
  Option(fn() -> Nil)

pub type Hook {
  Effect(effect_fn: fn() -> HookCleanup, trigger: HookTrigger)
  Callback(callback_fn: fn() -> Nil, trigger: HookTrigger)
}

pub type HookResult {
  EmptyResult
  HookResult(cleanup: HookCleanup, deps: Option(HookDependencies))
}
