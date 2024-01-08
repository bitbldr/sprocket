// TODO: Convert to gleam const
pub type Const {
  KeyAttr
  EventAttrPrefix
  IgnoreUpdateAttr
  ClientHookAttrPrefix
}

pub fn constant(c: Const) -> String {
  case c {
    KeyAttr -> "spkt-key"
    EventAttrPrefix -> "spkt-event"
    IgnoreUpdateAttr -> "spkt-ignore-update"
    ClientHookAttrPrefix -> "spkt-hook"
  }
}

pub fn call_timeout() -> Int {
  1000
}
// pub const call_timeout = 1000
