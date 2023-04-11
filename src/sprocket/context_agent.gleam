import gleam/otp/actor
import gleam/erlang/process.{Subject}
import gleam/list
import gleam/io
import gleam/result
import sprocket/component.{Hook}
import sprocket/render.{RenderContext}

pub fn start() {
  let initial_context =
    RenderContext(
      hooks: [],
      h_index: 0,
      pop_hook_index: fn() { 0 },
      push_hook: fn(_h) { todo },
      fetch_hook: fn(_h) { todo },
      state_updater: fn(_index) { fn(s) { s } },
    )

  let assert Ok(actor) = actor.start(initial_context, handle_message)

  actor
}

pub fn stop(actor) {
  process.send(actor, Shutdown)
}

pub fn fetch_context(actor) {
  let assert Ok(context) = process.call(actor, FetchContext, 10)

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
    hooks: context.hooks,
    h_index: context.h_index,
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
  FetchContext(reply_with: Subject(Result(RenderContext, Nil)))
  ResetHookIndex
  PopHookIndex(reply_with: Subject(Result(Int, Nil)))
}

fn handle_message(
  message: ContextMessage,
  context: RenderContext,
) -> actor.Next(RenderContext) {
  case message {
    Shutdown -> actor.Stop(process.Normal)

    PushHook(hook) -> {
      let r_hooks = list.reverse(context.hooks)
      let updated_hooks = list.reverse([hook, ..r_hooks])
      let new_state = RenderContext(..context, hooks: updated_hooks)

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

    ResetHookIndex -> actor.Continue(RenderContext(..context, h_index: 0))

    PopHookIndex(client) -> {
      process.send(client, Ok(context.h_index))
      actor.Continue(RenderContext(..context, h_index: context.h_index + 1))
    }
  }
}
