import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/http/service.{Service}
import gleam/bit_builder
import mist.{ResponseData}
import gleam/erlang/file
import gleam/result
import gleam/string
import gleam/list
import docs/utils/common.{mist_response}

pub fn middleware(
  service: Service(in, ResponseData),
) -> Service(in, ResponseData) {
  fn(request: Request(in)) -> Response(ResponseData) {
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
        |> mist_response()
      }
      Error(_) -> service(request)
    }
  }
}

@external(erlang, "sprocket_ffi", "priv_directory")
pub fn priv_directory() -> String
