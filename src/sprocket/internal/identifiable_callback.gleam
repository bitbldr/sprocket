import gleam/option.{Option}
import sprocket/internal/utils/unique.{Unique}

pub type CallbackFn =
  fn(Option(CallbackParam)) -> Nil

pub type CallbackParam {
  WithString(value: String)
}

pub type IdentifiableCallback {
  IdentifiableCallback(id: Unique, cb: CallbackFn)
}

pub fn from_string(value: String) -> CallbackParam {
  WithString(value)
}
