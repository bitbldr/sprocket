import gleam/option.{type Option, None, Some}

pub fn require(
  some optional: Option(a),
  otherwise bail: fn() -> b,
  do f: fn(a) -> b,
) -> b {
  case optional {
    Some(value) -> f(value)
    None -> bail()
  }
}
