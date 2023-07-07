import sprocket/utils/unique.{Unique}

pub type CallbackFn {
  CallbackFn(cb: fn() -> Nil)
  CallbackWithValueFn(cb: fn(String) -> Nil)
}

pub type IdentifiableCallback {
  IdentifiableCallback(id: Unique, cb: CallbackFn)
}
