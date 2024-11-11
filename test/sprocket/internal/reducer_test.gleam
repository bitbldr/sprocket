import sprocket/internal/reducer

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

pub fn reducer_should_dispatch() {
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
}
