// import gleam/io
// import gleam/int
// import gleam/option.{None, Some}
// import gleeunit/should
// import sprocket
// import sprocket/cassette
// import sprocket/socket.{Socket, Updater}
// import sprocket/patch.{Change, NoOp, Update}
// import sprocket/component.{component, render}
// import sprocket/html.{text}
// import sprocket/hooks.{WithDeps}
// import sprocket/hooks/reducer.{State, reducer}
// import sprocket/hooks/effect.{effect}

// type Model {
//   Model(count: Int)
// }

// type Msg {
//   UpdateCount(Int)
// }

// fn update(_model: Model, msg: Msg) -> Model {
//   case msg {
//     UpdateCount(count) -> {
//       Model(count: count)
//     }
//   }
// }

// fn initial() -> Model {
//   Model(0)
// }

// pub type CounterProps {
//   CounterProps
// }

// pub fn counter(socket: Socket, _props) {
//   // Define a reducer to handle events and update the state
//   use socket, State(Model(count: count), dispatch) <- reducer(
//     socket,
//     initial(),
//     update,
//   )

//   // Example effect with an empty list of dependencies, runs once on mount
//   use socket <- effect(
//     socket,
//     fn() {
//       dispatch(UpdateCount(count + 1))
//       None
//     },
//     WithDeps([]),
//   )

//   let current_count = int.to_string(count)

//   render(socket, [text(current_count)])
// }

// // TODO: figure out how to test components
// // gleeunit test functions end in `_test`
// pub fn effect_should_only_run_on_initial_render_test() {
//   let ca = cassette.start()

//   let view = component(counter, CounterProps)

//   let updater =
//     Updater(send: fn(update) {
//       io.debug(update)

//       // first call
//       update
//       |> should.equal(Update(None, Some([#(0, Change("1"))])))

//       // second call
//       update
//       |> should.equal(NoOp)

//       Ok(Nil)
//     })

//   let spkt = sprocket.start(None, Some(view), None)
//   cassette.push_sprocket(ca, spkt)

//   // intitial live render
//   let _rendered = sprocket.render(spkt)

//   sprocket.render_update(spkt)
// }
