import gleam/option.{None, Option, Some}
import sprocket/element.{Element}
import sprocket/html.{div}
import sprocket/html/attributes.{class}

/// Maybe return Some element if the condition is true
/// otherwise return None
pub fn maybe(condition: Bool, element: a) -> Option(a) {
  case condition {
    True -> Some(element)
    False -> None
  }
}

pub fn example(children: List(Element)) -> Element {
  div(
    [
      class(
        "not-prose graph-paper bg-white dark:bg-black my-4 p-6 border border-gray-200 dark:border-gray-700 rounded-md overflow-x-auto",
      ),
    ],
    children,
  )
}
