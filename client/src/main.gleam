import gleam/io

pub fn main() {
  console_log("Hello from client!")
}

external fn console_log(str: String) -> Nil =
  "" "console.log"
