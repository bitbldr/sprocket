pub type Const {
  KeyAttr
  EventAttrPrefix
  MetaPreflightId
  MetaCrsfToken
  ClientScript
}

pub fn constant(c: Const) -> String {
  case c {
    KeyAttr -> "spkt-key"
    EventAttrPrefix -> "spkt-event"
    MetaPreflightId -> "spkt-preflight-id"
    MetaCrsfToken -> "spkt-csrf-token"
    ClientScript -> "/client.js"
  }
}

pub fn call_timeout() -> Int {
  1000
}
