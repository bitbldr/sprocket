import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/result
import sprocket/component.{Hook}
import sprocket/render.{RenderContext}
import glisten/handler.{HandlerMessage}

pub type Client {
  Client(sub: Subject(HandlerMessage))
}

// TODO: hooks should be stored in a map for better access performance o(1), lists are o(n)
pub type ContextState {
  ContextState(hooks: List(Hook), h_index: Int, clients: List(Client))
}

pub fn start() {
  let initial_context = ContextState(hooks: [], h_index: 0, clients: [])

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

pub fn render_context(actor) {
  let push_hook = fn(h: Hook) {
    process.send(actor, PushHook(h))
    h
  }

  let fetch_hook = fn(i) { process.call(actor, FetchHook(_, i), 10) }

  process.send(actor, ResetHookIndex)
  let pop_hook_index = fn() {
    process.call(actor, PopHookIndex, 10)
    |> result.unwrap(0)
  }

  let state_updater = fn(_index) { fn(s) { s } }

  RenderContext(
    pop_hook_index: pop_hook_index,
    push_hook: push_hook,
    fetch_hook: fetch_hook,
    state_updater: state_updater,
  )
}

pub type ContextMessage {
  Shutdown
  PushHook(hook: Hook)
  FetchHook(reply_with: Subject(Result(Hook, Nil)), index: Int)
  FetchContext(reply_with: Subject(Result(ContextState, Nil)))
  ResetHookIndex
  PopHookIndex(reply_with: Subject(Result(Int, Nil)))
  PushClient(sender: Client)
  PopClient(sub: Subject(HandlerMessage))
}

fn handle_message(
  message: ContextMessage,
  context: ContextState,
) -> actor.Next(ContextState) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    PushHook(hook) -> {
      let r_hooks = list.reverse(context.hooks)
      let updated_hooks = list.reverse([hook, ..r_hooks])
      let new_state = ContextState(..context, hooks: updated_hooks)

      actor.Continue(new_state)
    }

    FetchHook(client, index) -> {
      let hook = list.at(context.hooks, index)

      case hook {
        Ok(h) -> {
          process.send(client, Ok(h))
          actor.Continue(context)
        }
        Error(Nil) -> {
          process.send(client, Error(Nil))
          actor.Continue(context)
        }
      }
    }

    FetchContext(client) -> {
      process.send(client, Ok(context))
      actor.Continue(context)
    }

    ResetHookIndex -> actor.Continue(ContextState(..context, h_index: 0))

    PopHookIndex(client) -> {
      process.send(client, Ok(context.h_index))
      actor.Continue(ContextState(..context, h_index: context.h_index + 1))
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
  }
}
