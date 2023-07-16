import gleam/erlang
import gleeunit/should
import sprocket/cassette.{Preflight}
import sprocket/internal/utils/uuid
import sprocket/internal/csrf
import sprocket/html.{div}

pub fn pushes_preflight_test() {
  let ca = cassette.start()

  let assert Ok(preflight_id) = uuid.v4()
  let view = div([], [])
  let csrf_token = csrf.generate()
  let created_at = erlang.system_time(erlang.Millisecond)

  let preflight = Preflight(preflight_id, view, csrf_token, created_at)

  cassette.push_preflight(ca, preflight)

  let assert Ok(Preflight(..) as popped) =
    cassette.pop_preflight(ca, preflight_id)

  popped.id
  |> should.equal(preflight_id)

  popped.view
  |> should.equal(view)

  popped.csrf_token
  |> should.equal(csrf_token)

  popped.created_at
  |> should.equal(created_at)
}
