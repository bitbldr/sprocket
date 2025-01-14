import gleam/option.{type Option, None, Some}

pub fn require_some(
  optional: Option(a),
  otherwise none: fn() -> b,
  then some: fn(a) -> b,
) -> b {
  case optional {
    Some(value) -> some(value)
    None -> none()
  }
}
