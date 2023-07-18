import gleam/erlang
import gleam/erlang/process
import gleeunit/should
import sprocket/cassette.{CleanupPreflights, Preflight}
import sprocket/internal/utils/uuid
import sprocket/internal/csrf
import sprocket/html.{div}

pub fn push_pop_preflight_test() {
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

pub fn cleanup_preflights_test() {
  let ca = cassette.start()

  let assert Ok(preflight_id) = uuid.v4()
  let view = div([], [])
  let csrf_token = csrf.generate()

  // set created at to 60 seconds ago
  let created_at = erlang.system_time(erlang.Millisecond) - 1000 * 60

  let preflight = Preflight(preflight_id, view, csrf_token, created_at)

  cassette.push_preflight(ca, preflight)

  process.send(ca, CleanupPreflights)

  let assert Ok(cassette.State(preflights: preflights, ..)) =
    process.call(ca, cassette.GetState(_), 1000)

  preflights
  |> should.equal([])
}
