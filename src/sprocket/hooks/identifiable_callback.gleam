pub type CallbackFn {
  CallbackFn(cb: fn() -> Nil)
  ChangedCallbackFn(cb: fn(String) -> Nil)
}

pub type IdentifiableCallback {
  IdentifiableCallback(id: String, cb: CallbackFn)
}
