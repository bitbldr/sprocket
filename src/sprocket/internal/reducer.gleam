import gleam/dynamic.{type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/function.{identity}
import gleam/list
import gleam/otp/actor
import gleam/result
import sprocket/internal/constants.{call_timeout}

pub type ReducerActor {
  Initialized(start: fn() -> Dynamic)
  Running(reducer: Dynamic, cleanup: fn() -> Nil)
}

pub type Dispatcher(msg) =
  fn(msg) -> Nil

pub type Cmd(msg) =
  fn(Dispatcher(msg)) -> Nil

pub type UpdateFn(model, msg) =
  fn(model, msg) -> #(model, List(Cmd(msg)))

pub type ReducerMessage(model, msg) {
  Shutdown
  GetState(reply_with: Subject(model))
  ReducerDispatch(msg: msg)
}

pub opaque type State(model, msg) {
  State(
    self: Subject(ReducerMessage(model, msg)),
    model: model,
    update: UpdateFn(model, msg),
    notify: fn(model) -> Nil,
  )
}

pub fn init(
  initial: model,
  update: UpdateFn(model, msg),
  notify: fn(model) -> Nil,
) -> fn() -> actor.InitResult(State(model, msg), ReducerMessage(model, msg)) {
  fn() {
    let self = process.new_subject()
    let selector = process.selecting(process.new_selector(), self, identity)

    actor.Ready(State(self, initial, update, notify), selector)
  }
}

pub fn handle_message(
  message: ReducerMessage(model, msg),
  state,
) -> actor.Next(ReducerMessage(model, msg), State(model, msg)) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    GetState(reply_with) -> {
      let State(model:, ..) = state

      process.send(reply_with, model)

      actor.continue(state)
    }

    ReducerDispatch(msg) -> {
      let State(self:, model:, update:, notify:) = state

      // This is the main logic for updating the reducer's state. The reducer function will
      // return the updated model and a list of zero or more commands to execute. The commands
      // are functions that will be called with the dispatcher function which may trigger
      // additional messages to the reducer.
      let #(updated_model, cmds) = update(model, msg)

      async_process_commands(cmds, dispatch(self, _))

      // Notiify the parent component that the state has been updated. In the case
      // of a view component, this will trigger a re-render. The re-render will call
      // this actor to get the latest state, which will always be processed after this
      // current message, ensuring that the state returned by get_state represents the
      // latest model.
      notify(model)

      actor.continue(State(..state, model: updated_model))
    }
  }
}

/// Starts a new reducer actor with the given initial state and commands, update function, and
/// notify callback.
/// 
/// A reducer actor is a a wrapper around an OTP actor that manages a single piece of state and a
/// set of commands that can be executed to update that state. The update function is called with the
/// current state and a message, and returns the new state and a list of commands to execute. The
/// notify function is called whenever the state is updated.
pub fn start(
  initial: #(model, List(Cmd(msg))),
  update: UpdateFn(model, msg),
  notify: fn(model) -> Nil,
) {
  let #(model, cmds) = initial

  use self <- result.map(
    actor.start_spec(actor.Spec(
      init(model, update, notify),
      call_timeout,
      handle_message,
    )),
  )

  async_process_commands(cmds, dispatch(self, _))

  self
}

/// Shuts down the reducer actor.
pub fn shutdown(subject) {
  process.send(subject, Shutdown)
}

/// Gets the current state of the reducer actor.
pub fn get_state(subject) -> model {
  process.call(subject, GetState(_), call_timeout)
}

/// Dispatches a message to the reducer actor.
pub fn dispatch(subject: Subject(ReducerMessage(model, msg)), msg: msg) -> Nil {
  // this will update the reducer's state and trigger a change notification. To ensure we re-render
  // with the latest state, this message must be processed before the next render cycle. However,
  // because we also use a process.call to the same reducer actor to get the current state, we should
  // be guaranteed to have this message processed before that call during the next render cycle.
  actor.send(subject, ReducerDispatch(msg))
}

fn async_process_commands(cmds, dispatcher) -> Nil {
  cmds
  |> list.each(fn(cmd) { process.start(fn() { cmd(dispatcher) }, False) })
}
