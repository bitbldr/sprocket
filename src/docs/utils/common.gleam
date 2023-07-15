import gleam/option.{None, Option, Some}

/// Maybe return Some element if the condition is true
/// otherwise return None
pub fn maybe(condition: Bool, element: a) -> Option(a) {
  case condition {
    True -> Some(element)
    False -> None
  }
}
