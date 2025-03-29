import gleam/list
import sprocket/internal/reducer

type Model =
  Int

type Msg {
  Increment
  Set(Int)
  Reset
}

fn init(value) {
  fn(_dispatch) { value }
}

fn update(model, msg, _dispatch) -> Model {
  case msg {
    Increment -> model + 1
    Set(value) -> value
    Reset -> 0
  }
}

pub fn reducer_should_dispatch_test() {
  let assert Ok(reducer_actor) = reducer.start(init(0), update, fn(_) { Nil })

  reducer.dispatch(reducer_actor, Increment)

  let state = reducer.get_model(reducer_actor)

  let assert True = state == 1

  reducer.dispatch(reducer_actor, Increment)

  let state = reducer.get_model(reducer_actor)

  let assert True = state == 2

  reducer.dispatch(reducer_actor, Reset)

  let state = reducer.get_model(reducer_actor)

  let assert True = state == 0

  reducer.shutdown(reducer_actor)
}

fn init_with_commands(value, cmds) {
  fn(dispatch) {
    list.each(cmds, fn(cmd) { cmd(dispatch) })

    value
  }
}

fn increment_cmd(dispatch) {
  dispatch(Increment)
}

pub fn reducer_should_process_initial_cmd_test() {
  let assert Ok(reducer_actor) =
    reducer.start(init_with_commands(0, [increment_cmd]), update, fn(_) { Nil })

  let state = reducer.get_model(reducer_actor)

  let assert True = state == 1

  let state = reducer.get_model(reducer_actor)

  let assert True = state == 1

  reducer.dispatch(reducer_actor, Reset)

  let state = reducer.get_model(reducer_actor)

  let assert True = state == 0

  reducer.shutdown(reducer_actor)
}

pub fn reducer_should_process_multiple_cmds_test() {
  let assert Ok(reducer_actor) =
    reducer.start(
      init_with_commands(0, [increment_cmd, increment_cmd, increment_cmd]),
      update,
      fn(_) { Nil },
    )

  let state = reducer.get_model(reducer_actor)

  let assert True = state == 3

  reducer.dispatch(reducer_actor, Reset)

  let state = reducer.get_model(reducer_actor)

  let assert True = state == 0

  reducer.shutdown(reducer_actor)
}
