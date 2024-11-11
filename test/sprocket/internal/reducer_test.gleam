import sprocket/internal/reducer
import sprocket/test_helpers

type Model =
  Int

type Msg {
  Increment
  Set(Int)
  Reset
}

fn init(value) -> #(Model, List(reducer.Cmd(Msg))) {
  #(value, [])
}

fn update(model, msg) -> #(Model, List(reducer.Cmd(Msg))) {
  case msg {
    Increment -> #(model + 1, [])
    Set(value) -> #(value, [])
    Reset -> #(0, [])
  }
}

pub fn reducer_should_dispatch_test() {
  let assert Ok(reducer_actor) = reducer.start(init(0), update, fn(_) { Nil })

  reducer.dispatch(reducer_actor, Increment)

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 1

  reducer.dispatch(reducer_actor, Increment)

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 2

  reducer.dispatch(reducer_actor, Reset)

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 0

  reducer.shutdown(reducer_actor)
}

fn init_with_commands(value, cmds) -> #(Model, List(reducer.Cmd(Msg))) {
  #(value, cmds)
}

fn increment_cmd() -> reducer.Cmd(Msg) {
  fn(dispatch) { dispatch(Increment) }
}

pub fn reducer_should_process_initial_cmd_test() {
  let assert Ok(reducer_actor) =
    reducer.start(init_with_commands(0, [increment_cmd()]), update, fn(_) {
      Nil
    })

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 0

  reducer.process_commands(reducer_actor)

  test_helpers.wait_until(
    fn() {
      let state = reducer.get_state(reducer_actor)

      state == 1
    },
    1000,
  )

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 1

  reducer.dispatch(reducer_actor, Reset)

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 0

  reducer.shutdown(reducer_actor)
}

pub fn reducer_should_process_multiple_cmds_test() {
  let assert Ok(reducer_actor) =
    reducer.start(
      init_with_commands(0, [increment_cmd(), increment_cmd(), increment_cmd()]),
      update,
      fn(_) { Nil },
    )

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 0

  reducer.process_commands(reducer_actor)

  test_helpers.wait_until(
    fn() {
      let state = reducer.get_state(reducer_actor)

      state == 3
    },
    1000,
  )

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 3

  reducer.dispatch(reducer_actor, Reset)

  let state = reducer.get_state(reducer_actor)

  let assert True = state == 0

  reducer.shutdown(reducer_actor)
}
