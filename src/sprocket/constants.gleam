pub type Const {
  KeyAttr
  EventAttr
}

pub fn spkt_const(c: Const) -> String {
  case c {
    KeyAttr -> "live-key"
    EventAttr -> "live-event"
  }
}
