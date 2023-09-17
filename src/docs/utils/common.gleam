import gleam/option.{None, Option, Some}
import gleam/bit_builder.{BitBuilder}
import gleam/http/response.{Response}
import gleam/crypto
import gleam/base
import gleam/string
import mist.{ResponseData}
import sprocket/context.{Element}
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

pub fn mist_response(response: Response(BitBuilder)) -> Response(ResponseData) {
  response.new(response.status)
  |> response.set_body(mist.Bytes(response.body))
}

/// Generate a random string of the given length
pub fn random_string(length: Int) -> String {
  crypto.strong_random_bytes(length)
  |> base.url_encode64(False)
  |> string.slice(0, length)
}
