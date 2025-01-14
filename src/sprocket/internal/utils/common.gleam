import gleam/option.{type Option, Some, None}

pub fn require_some(optional: Option(a), or none: fn() -> b, then some: fn(a) -> b) -> b {
  case optional {
    Some(value) -> some(value)
    None -> none()
  }
}
