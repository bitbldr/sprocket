import gleam/list
import gleam/option.{Option}
import gleam/dynamic.{Dynamic}
import sprocket/internal/exceptions.{throw_on_unexpected_deps_mismatch}
import sprocket/internal/identifiable_callback.{CallbackFn}
import sprocket/internal/utils/unique.{Unique}

pub type HookDependencies =
  List(Dynamic)

// helper function to create a dependency from a value
pub fn dep(dependency: a) -> Dynamic {
  dynamic.from(dependency)
}

pub type HookTrigger {
  OnMount
  OnUpdate
  WithDeps(deps: HookDependencies)
}

pub type EffectCleanup =
  Option(fn() -> Nil)

pub type EffectResult {
  EffectResult(cleanup: EffectCleanup, deps: Option(HookDependencies))
}

pub type CallbackResult {
  CallbackResult(callback: CallbackFn, deps: Option(HookDependencies))
}

pub type ClientDispatcher =
  fn(String, Option(String)) -> Result(Nil, Nil)

pub type ClientEventHandler =
  fn(String, Option(Dynamic), ClientDispatcher) -> Nil

pub type Hook {
  Callback(
    id: Unique,
    callback: CallbackFn,
    trigger: HookTrigger,
    prev: Option(CallbackResult),
  )
  Effect(
    id: Unique,
    effect: fn() -> EffectCleanup,
    trigger: HookTrigger,
    prev: Option(EffectResult),
  )
  Reducer(id: Unique, reducer: Dynamic, cleanup: fn() -> Nil)
  State(id: Unique, value: Dynamic)
  Client(id: Unique, name: String, handle_event: Option(ClientEventHandler))
}

pub type Compared(a) {
  Changed(changed: a)
  Unchanged
}

pub fn compare_deps(
  prev_deps: HookDependencies,
  deps: HookDependencies,
) -> Compared(HookDependencies) {
  // zip deps together and compare each one with the previous to see if they are equal
  case list.strict_zip(prev_deps, deps) {
    Error(list.LengthMismatch) ->
      // Dependency lists are different sizes, so they must have changed
      // this should never occur and means that a hook's deps list was dynamically changed
      throw_on_unexpected_deps_mismatch(#("compare_deps", prev_deps, deps))

    Ok(zipped_deps) -> {
      case
        list.all(
          zipped_deps,
          fn(z) {
            let #(a, b) = z
            a == b
          },
        )
      {
        True -> Unchanged
        _ -> Changed(deps)
      }
    }
  }
}
