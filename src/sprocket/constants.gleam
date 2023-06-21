pub type Const {
  KeyAttr
  EventAttrPrefix
}

pub fn c(constant: Const) -> String {
  case constant {
    KeyAttr -> "spkt-key"
    EventAttrPrefix -> "spkt-event"
  }
}
