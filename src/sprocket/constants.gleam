pub type Const {
  KeyAttr
  EventAttrPrefix
}

pub fn const_str(constant: Const) -> String {
  case constant {
    KeyAttr -> "spkt-key"
    EventAttrPrefix -> "spkt-event"
  }
}
