import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/http/service.{Service}
import gleam/bit_builder.{BitBuilder}
import gleam/erlang/file
import gleam/result
import gleam/string
import gleam/list

pub fn middleware(service: Service(in, BitBuilder)) -> Service(in, BitBuilder) {
  fn(request: Request(in)) -> Response(BitBuilder) {
    let request_path = case request.path {
      "/" -> "/index.html"
      path -> path
    }

    let path =
      request_path
      |> string.replace(each: "..", with: "")
      |> string.replace(each: "//", with: "/")
      |> string.append("/static", _)
      |> string.append(priv_directory(), _)

    let file_contents =
      path
      |> file.read_bits
      |> result.nil_error
      |> result.map(bit_builder.from_bit_string)

    let extension =
      path
      |> string.split(on: ".")
      |> list.last
      |> result.unwrap("")

    case file_contents {
      Ok(bits) -> {
        let content_type = case extension {
          "html" -> "text/html"
          "css" -> "text/css"
          "js" -> "application/javascript"
          "png" | "jpg" -> "image/jpeg"
          "gif" -> "image/gif"
          "svg" -> "image/svg+xml"
          "ico" -> "image/x-icon"
          _ -> "octet-stream"
        }
        Response(200, [#("content-type", content_type)], bits)
      }
      Error(_) -> service(request)
    }
  }
}

pub external fn priv_directory() -> String =
  "sprocket_ffi" "priv_directory"
