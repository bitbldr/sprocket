import gleam/list
import gleam/option.{Option}
import gleam/dynamic.{Dynamic}
import sprocket/exception.{throw_on_unexpected_deps_mismatch}

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
    id: String,
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
