import gleam/dynamic
import gleam/otp/actor
import gleam/erlang/process.{Subject}
import sprocket/element.{Element}
import sprocket/internal/socket.{Socket}
import sprocket/internal/hooks
import sprocket/internal/utils/unique
import sprocket/internal/constants.{call_timeout}

pub type Updater(msg) =
  fn(msg) -> Nil

pub type State(model, msg) {
  State(m: model, d: Updater(msg))
}

type Reducer(model, msg) =
  fn(model, msg) -> model

type StateOrDispatchReducer(model, msg) {
  Shutdown
  StateReducer(reply_with: Subject(model))
  DispatchReducer(r: Reducer(model, msg), m: msg)
}

pub fn reducer(
  socket: Socket,
  initial: model,
  reducer: Reducer(model, msg),
  cb: fn(Socket, State(model, msg)) -> #(Socket, List(Element)),
) -> #(Socket, List(Element)) {
  let Socket(render_update: render_update, ..) = socket

  let reducer_init = fn() {
    // creates an actor process for a reducer that handles two types of messages:
    //  1. StateReducer msg, which simply returns the state of the reducer
    //  2. DispatchReducer msg, which will update the reducer state when a dispatch is triggered
    let assert Ok(reducer_actor) =
      actor.start(
        initial,
        fn(message: StateOrDispatchReducer(model, msg), state: model) -> actor.Next(
          model,
        ) {
          case message {
            Shutdown -> actor.Stop(process.Normal)

            StateReducer(reply_with) -> {
              process.send(reply_with, state)
              actor.Continue(state)
            }

            DispatchReducer(r, m) -> {
              r(state, m)
              |> actor.Continue()
            }
          }
        },
      )

    hooks.Reducer(
      unique.new(),
      dynamic.from(reducer_actor),
      fn() { process.send(reducer_actor, Shutdown) },
    )
  }

  let assert #(socket, hooks.Reducer(_id, dyn_reducer_actor, _cleanup), _index) =
    socket.fetch_or_init_hook(socket, reducer_init)

  // we dont know what types of reducer messages a component will implement so the best
  // we can do is store the actors as dynamic and coerce them back when updating
  let reducer_actor = dynamic.unsafe_coerce(dyn_reducer_actor)

  // get the current state of the reducer
  let state = process.call(reducer_actor, StateReducer(_), call_timeout())

  // create a dispatch function for updating the reducer's state and triggering a render update
  let dispatch = fn(msg) -> Nil {
    // TODO: we might need to wait for the reducer to finish updating before triggering a render update
    actor.send(reducer_actor, DispatchReducer(r: reducer, m: msg))
    render_update()

    Nil
  }

  cb(socket, State(state, dispatch))
}
