pub type Const {
  KeyAttr
  EventAttrPrefix
}

pub fn constant(c: Const) -> String {
  case c {
    KeyAttr -> "spkt-key"
    EventAttrPrefix -> "spkt-event"
  }
}
