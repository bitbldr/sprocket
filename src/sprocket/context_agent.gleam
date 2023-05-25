import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/dynamic.{Dynamic}
import sprocket/render.{RenderContext}
import glisten/handler.{HandlerMessage}
import sprocket/uuid

pub type ContextAgent =
  Subject(ContextMessage)

pub type Client {
  Client(sub: Subject(HandlerMessage))
}

pub type EventHandler {
  EventHandler(id: String, handler: fn() -> Nil)
}

// TODO: hooks and reducers should be stored in a map for better access performance o(1), lists are o(n)
pub type ContextState {
  ContextState(
    r_index: Int,
    clients: List(Client),
    reducers: List(Dynamic),
    handlers: List(EventHandler),
  )
}

pub fn start() {
  let initial_context =
    ContextState(r_index: 0, clients: [], reducers: [], handlers: [])

  let assert Ok(actor) = actor.start(initial_context, handle_message)

  actor
}

pub fn stop(actor) {
  process.send(actor, Shutdown)
}

pub fn push_client(actor, client) {
  process.send(actor, PushClient(client))
}

pub fn pop_client(actor, sub) {
  process.send(actor, PopClient(sub))
}

pub fn get_handler(actor, id) {
  process.call(actor, GetEventHandler(_, id), 10)
}

pub fn render_context(actor) {
  // reset for new render cycle
  process.send(actor, ResetReducerIndex)
  process.send(actor, ResetEventHandlers)

  let fetch_or_create_reducer = fn(reducer) {
    process.call(actor, FetchOrCreateReducer(_, reducer), 10)
  }

  let push_event_handler = fn(handler) {
    process.call(actor, PushEventHandler(_, handler), 10)
  }

  RenderContext(
    fetch_or_create_reducer: fetch_or_create_reducer,
    push_event_handler: push_event_handler,
  )
}

pub type ContextMessage {
  Shutdown
  FetchContext(reply_with: Subject(Result(ContextState, Nil)))
  FetchOrCreateReducer(
    reply_with: Subject(Dynamic),
    reducer_init: fn() -> Dynamic,
  )
  ResetReducerIndex
  PushClient(sender: Client)
  PopClient(sub: Subject(HandlerMessage))
  PushEventHandler(reply_with: Subject(String), handler: fn() -> Nil)
  GetEventHandler(reply_with: Subject(Result(EventHandler, Nil)), id: String)
  ResetEventHandlers
}

fn handle_message(
  message: ContextMessage,
  context: ContextState,
) -> actor.Next(ContextState) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    FetchContext(client) -> {
      process.send(client, Ok(context))
      actor.Continue(context)
    }

    ResetReducerIndex -> actor.Continue(ContextState(..context, r_index: 0))

    FetchOrCreateReducer(client, reducer_init) -> {
      case list.at(context.reducers, context.r_index) {
        Ok(r) -> {
          // reducer found, return it
          process.send(client, r)
          actor.Continue(ContextState(..context, r_index: context.r_index + 1))
        }
        Error(Nil) -> {
          // reducer doesnt exist, create it
          let reducer = reducer_init()
          let r_reducers = list.reverse(context.reducers)
          let updated_reducers = list.reverse([reducer, ..r_reducers])
          let new_state =
            ContextState(
              ..context,
              reducers: updated_reducers,
              r_index: context.r_index + 1,
            )

          process.send(client, reducer)
          actor.Continue(new_state)
        }
      }
    }

    PushClient(client) -> {
      let r_clients = list.reverse(context.clients)
      let updated_clients = list.reverse([client, ..r_clients])
      let new_state = ContextState(..context, clients: updated_clients)

      actor.Continue(new_state)
    }

    PopClient(sub) -> {
      let updated_clients =
        list.filter(
          context.clients,
          fn(c) {
            let assert Client(s) = c
            s != sub
          },
        )
      let new_state = ContextState(..context, clients: updated_clients)

      actor.Continue(new_state)
    }

    PushEventHandler(client, handler) -> {
      let assert Ok(id) = uuid.v4()
      let new_state =
        ContextState(
          ..context,
          handlers: [EventHandler(id, handler), ..context.handlers],
        )

      process.send(client, id)

      actor.Continue(new_state)
    }

    GetEventHandler(client, id) -> {
      let handler =
        list.find(
          context.handlers,
          fn(h) {
            let EventHandler(i, _) = h
            i == id
          },
        )

      process.send(client, handler)

      actor.Continue(context)
    }

    ResetEventHandlers -> {
      let new_state = ContextState(..context, handlers: [])

      actor.Continue(new_state)
    }
  }
}
