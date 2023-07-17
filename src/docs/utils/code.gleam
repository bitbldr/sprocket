import gleam/string
import gleam/list
import gleam/int
import sprocket/html.{code, div, ignored, pre}
import sprocket/html/attribute.{class}

pub fn code_snippet(language: String, body: String) {
  div(
    [class("not-prose")],
    [
      ignored(pre(
        [],
        [
          code(
            [class("language-" <> language <> " rounded-lg")],
            process_code(body),
          ),
        ],
      )),
    ],
  )
}

pub fn process_code(code: String) {
  // trim leading and trailing whitespace
  let code =
    code
    |> string.trim()

  // normalize leading whitespace to the minimum amount found on any single line
  let min_leading_spaces =
    code
    |> string.split("\n")
    |> list.fold(
      0,
      fn(acc, line) {
        case acc, count_leading_spaces(line, 0) {
          0, count -> count
          _, 0 -> acc
          _, count -> int.min(acc, count)
        }
      },
    )

  code
  |> string.split("\n")
  |> list.map(fn(line) {
    case string.pop_grapheme(line) {
      // check if the line has leading whitespace. if so, trim it to the minimum
      // amount found on any single line. otherwise, return the line as-is.
      Ok(#(" ", _)) -> {
        string.slice(
          line,
          min_leading_spaces,
          string.length(line) - min_leading_spaces,
        )
      }
      _ -> line
    }
  })
  |> string.join("\n")
}

fn count_leading_spaces(line: String, count: Int) {
  case string.pop_grapheme(line) {
    Ok(#(" ", rest)) -> count_leading_spaces(rest, count + 1)
    _ -> count
  }
}