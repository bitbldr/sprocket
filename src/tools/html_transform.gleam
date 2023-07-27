import gleam/io
import gleam/list
import gleam/regex
import gleam/string
import gleam/erlang.{start_arguments}
import gleam/erlang/file
import glint.{CommandInput}
import glint/flag

/// A very fragile script to transform a file of html tags into sprocket element/attribute functions
/// 
/// ```
/// <a>
/// <animate>
/// <animateMotion>
/// <animateTransform>
/// ...
/// ```
/// 
/// Example:
/// > gleam run -m tools/html_transform -- --template=elements src/sprocket/html/svg/source/elements
/// 
/// Will create a file src/sprocket/html/svg.gleam
/// 
pub fn main() {
  glint.new()
  |> glint.with_pretty_help(glint.default_pretty_help())
  |> glint.add_command(
    at: [],
    do: transform,
    with: [
      flag.string("template", "", "Template to use for the transformation"),
    ],
    described: "transforms a list of html tags into sprocket elements",
  )
  |> glint.run(start_arguments())
}

fn transform(input: CommandInput) {
  let assert Ok(flag.S(template)) = flag.get(from: input.flags, for: "template")
  let assert Ok(filepath) = list.at(input.args, 0)

  let assert Ok(contents) = file.read(filepath)

  let lines = string.split(contents, "\n")

  let result =
    lines
    |> list.filter_map(fn(line) {
      case string.trim(line) {
        "" -> {
          Error(Nil)
        }
        original -> {
          case
            original
            |> string.starts_with("//")
          {
            True -> {
              // ignore comment line
              Error(Nil)
            }
            False -> {
              let tag =
                original
                |> string.replace("-", "_")
                |> string.replace(":", "_")
                |> snake_case()

              template_for(original, tag, template)
              |> string.join("\n")
              |> Ok
            }
          }
        }
      }
    })
    |> string.join("\n\n")

  let assert Ok(_) = file.write(result, filepath <> ".gleam")
}

fn template_for(original: String, tag: String, template: String) {
  case string.lowercase(template) {
    "elements" -> [
      "/// The [SVG `<" <> original <> ">` element](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/" <> original <> ")",
      "pub fn " <> tag <> "(attrs: List(Attribute), children: List(Element)) {",
      "  el(\"" <> original <> "\", attrs, children)",
      "}",
    ]
    "attributes" -> [
      "/// The [SVG `" <> original <> "` attribute](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/" <> original <> ")",
      "pub fn " <> tag <> "(value: String) -> Attribute {",
      "  attribute(\"" <> original <> "\", value)",
      "}",
    ]
    _ -> {
      io.print(
        "Error: No template provided. Use `--template=elements` or `--template=attributes`\n\n",
      )
      panic
    }
  }
}

pub fn snake_case(input: String) -> String {
  snake_case_helper(input, "")
}

fn snake_case_helper(input: String, acc: String) -> String {
  case string.pop_grapheme(input) {
    // Base case: If the input is empty, return the accumulated string.
    Error(Nil) -> acc

    // If the first character is uppercase, add an underscore and its lowercase version to the accumulated string.
    Ok(#(c, rest)) -> {
      let assert Ok(re) = regex.from_string("[A-Z]")

      case regex.check(re, c) {
        True -> {
          snake_case_helper(rest, acc <> "_" <> string.lowercase(c))
        }
        False -> {
          // If the first character is not uppercase, add it as is to the accumulated string.
          snake_case_helper(rest, acc <> string.lowercase(c))
        }
      }
    }
  }
}
// fn snake_case(str: String) {
//   let assert Ok(re) = regex.from_string("^[A-Z]")

//   case regex.split(with: re, content: str) {
//     [str] -> {
//       str
//     }

//     parts -> {
//       snake_parts(parts, "")
//     }
//   }
// }

// fn snake_parts(parts: List(String), acc: String) {
//   case parts {
//     [] -> {
//       acc
//     }
//     [first, ..rest] -> {
//       case acc {
//         "" -> {
//           snake_parts(rest, string.lowercase(first))
//         }
//         _ -> {
//           snake_parts(rest, acc <> "_" <> string.lowercase(first))
//         }
//       }
//     }
//   }
// }
