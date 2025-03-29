import gleam/dynamic.{type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/function.{identity}
import gleam/otp/actor
import gleam/result
import sprocket/internal/constants.{call_timeout}

pub type ReducerActor {
  Initialized(start: fn() -> Dynamic)
  Running(reducer: Dynamic, cleanup: fn() -> Nil)
}

pub type Dispatcher(msg) =
  fn(msg) -> Nil

pub type Notifier(model) =
  fn(model) -> Nil

pub type Initializer(model, msg) =
  fn(Dispatcher(msg)) -> model

pub type Updater(model, msg) =
  fn(model, msg, Dispatcher(msg)) -> model

pub type ReducerMessage(model, msg) {
  Shutdown
  GetModel(reply_with: Subject(model))
  ReducerDispatch(msg: msg)
}

pub opaque type State(model, msg) {
  State(
    self: Subject(ReducerMessage(model, msg)),
    model: model,
    update: Updater(model, msg),
    notify: Notifier(model),
  )
}

pub fn init(
  initialize: Initializer(model, msg),
  update: Updater(model, msg),
  notify: Notifier(model),
) -> fn() -> actor.InitResult(State(model, msg), ReducerMessage(model, msg)) {
  fn() {
    let self = process.new_subject()
    let selector = process.selecting(process.new_selector(), self, identity)

    let dispach = fn(msg) { process.send(self, ReducerDispatch(msg)) }

    actor.Ready(State(self, initialize(dispach), update, notify), selector)
  }
}

pub fn handle_message(
  message: ReducerMessage(model, msg),
  state,
) -> actor.Next(ReducerMessage(model, msg), State(model, msg)) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    GetModel(reply_with) -> {
      let State(model:, ..) = state

      process.send(reply_with, model)

      actor.continue(state)
    }

    ReducerDispatch(msg) -> {
      let State(self:, model:, update:, notify:) = state

      let dispach = fn(msg) { process.send(self, ReducerDispatch(msg)) }

      // This is the main logic for updating the reducer's state. The update function will
      // return the updated model. A dispatcher function is passed to update, which can
      // be used to dispatch messages to the reducer actor. This is useful for dispatching
      // continuations or from async operations.
      let updated_model = update(model, msg, dispach)

      // Notify the subscriber if the model has changed. In the case
      // of a view component, this will trigger a re-render. The re-render will call
      // this actor to get the latest state, which will always be processed after this
      // current message, ensuring that the state returned by get_state represents the
      // latest model.
      case model != updated_model {
        True -> notify(updated_model)
        _ -> Nil
      }

      actor.continue(State(..state, model: updated_model))
    }
  }
}

/// Starts a new reducer actor with the initial state from the initializer, update function, and
/// notify callback.
/// 
/// A reducer actor is a a wrapper around an OTP actor that manages a single piece of state. The
//update function is called with the current state, a message and a dispatcher function. The dispatcher

/// function can be used to dispatch messages to the reducer actor. The update function is expected to
/// return the new state. The notify function is called whenever the state is updated.
pub fn start(
  initialize: Initializer(model, msg),
  update: Updater(model, msg),
  notify: fn(model) -> Nil,
) {
  use self <- result.map(
    actor.start_spec(actor.Spec(
      init(initialize, update, notify),
      call_timeout,
      handle_message,
    )),
  )

  self
}

/// Shuts down the reducer actor.
pub fn shutdown(subject) {
  process.send(subject, Shutdown)
}

/// Returns the current model of the reducer actor.
pub fn get_model(subject) -> model {
  process.call(subject, GetModel, call_timeout)
}

/// Dispatches a message to the reducer actor.
pub fn dispatch(subject: Subject(ReducerMessage(model, msg)), msg: msg) -> Nil {
  // this will update the reducer's state and trigger a change notification. To ensure we re-render
  // with the latest state, this message must be processed before the next render cycle. However,
  // because we also use a process.call to the same reducer actor to get the current state, we should
  // be guaranteed to have this message processed before that call during the next render cycle.
  actor.send(subject, ReducerDispatch(msg))
}
