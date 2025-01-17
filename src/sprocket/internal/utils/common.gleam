import gleam/option.{type Option, None, Some}

pub fn require(
  optional optional: Option(a),
  or_else bail: fn() -> b,
  do f: fn(a) -> b,
) -> b {
  case optional {
    Some(value) -> f(value)
    None -> bail()
  }
}
