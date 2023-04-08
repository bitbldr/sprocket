import example/routes
import example/log
import gleam/int
import gleam/string
import gleam/result
import gleam/erlang/os
import gleam/erlang/process
import mist

pub fn main() {
  log.configure_backend()
  let port = load_port()
  let web = routes.stack()

  string.concat(["Listening on localhost:", int.to_string(port), " ✨"])
  |> log.info

  let assert Ok(_) = mist.run_service(port, web, max_body_limit: 4_000_000)
  process.sleep_forever()
}

fn load_port() -> Int {
  os.get_env("PORT")
  |> result.then(int.parse)
  |> result.unwrap(3000)
}
