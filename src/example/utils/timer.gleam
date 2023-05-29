import gleam/otp/actor.{Next}
import gleam/erlang/process.{Subject}

type TimerInterval =
  Int

type TimerMsg {
  Cancel
  Timeout(cb: fn() -> Nil)
  Interval(actor: Subject(TimerMsg), interval_ms: Int, cb: fn() -> Nil)
}

fn handle_timer_message(
  msg: TimerMsg,
  state: TimerInterval,
) -> Next(TimerInterval) {
  case msg {
    Cancel -> {
      actor.Stop(process.Normal)
    }
    Timeout(cb) -> {
      cb()
      actor.Stop(process.Normal)
    }
    Interval(actor, interval_ms, cb) -> {
      cb()
      process.send_after(actor, interval_ms, Interval(actor, interval_ms, cb))
      actor.Continue(state)
    }
  }
}

pub fn timer(interval_ms: Int, callback: fn() -> Nil) {
  let assert Ok(actor) = actor.start(interval_ms, handle_timer_message)

  // actor will terminate on Timeout
  process.send_after(actor, interval_ms, Timeout(callback))
}

pub fn interval(interval_ms: Int, callback: fn() -> Nil) {
  let assert Ok(actor) = actor.start(interval_ms, handle_timer_message)

  process.send_after(actor, interval_ms, Interval(actor, interval_ms, callback))

  // return a callback to cancel the timer
  fn() { actor.send(actor, Cancel) }
}
