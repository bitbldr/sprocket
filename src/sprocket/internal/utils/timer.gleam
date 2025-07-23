import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/otp/actor.{type Next}
import gleam/result
import gleam/string
import sprocket/internal/logger

type TimerInterval =
  Int

type TimerMsg {
  Cancel
  Timeout(cb: fn() -> Nil)
  Interval(actor: Subject(TimerMsg), interval_ms: Int, cb: fn() -> Nil)
}

fn handle_timer_message(
  state: TimerInterval,
  msg: TimerMsg,
) -> Next(TimerInterval, TimerMsg) {
  case msg {
    Cancel -> {
      actor.stop()
    }
    Timeout(cb) -> {
      cb()
      actor.stop()
    }
    Interval(actor, interval_ms, cb) -> {
      cb()
      process.send_after(actor, interval_ms, Interval(actor, interval_ms, cb))
      actor.continue(state)
    }
  }
}

pub fn timer(interval_ms: Int, callback: fn() -> Nil) {
  let assert Ok(actor.Started(data: actor, ..)) =
    actor.new(interval_ms)
    |> actor.on_message(handle_timer_message)
    |> actor.start()
    |> result.map_error(fn(error) {
      logger.error("timer.timer: failed to start timer actor")
      error
    })

  // actor will terminate on Timeout
  process.send_after(actor, interval_ms, Timeout(callback))
}

pub fn interval(interval_ms: Int, callback: fn() -> Nil) {
  let assert Ok(actor.Started(data: actor, ..)) =
    actor.new(interval_ms)
    |> actor.on_message(handle_timer_message)
    |> actor.start()
    |> result.map_error(fn(error) {
      logger.error("timer.interval: failed to start timer actor")
      error
    })

  process.send_after(actor, interval_ms, Interval(actor, interval_ms, callback))

  // return a callback to cancel the timer
  fn() { actor.send(actor, Cancel) }
}

pub fn timed_operation(label: String, cb: fn() -> a) -> a {
  let op_timer = begin_timed_operation(label)
  let result = cb()
  complete_timed_operation(op_timer)

  result
}

type TimedOperation {
  TimedOperation(label: String, begin_timestamp_us: Int)
}

fn begin_timed_operation(label: String) -> TimedOperation {
  logger.debug(string.concat(["Starting ", label, "..."]))

  TimedOperation(label, now())
}

fn complete_timed_operation(op: TimedOperation) -> Int {
  let elapsed =
    convert_time_unit(now() - op.begin_timestamp_us, Native, Microsecond)

  let formatted_elapsed = case elapsed > 1000 {
    True -> string.append(int.to_string(elapsed / 1000), "ms")
    False -> string.append(int.to_string(elapsed), "µs")
  }

  string.concat([op.label, " completed in ", formatted_elapsed])
  |> logger.debug

  elapsed
}

pub type TimeUnit {
  Native
  Microsecond
}

@external(erlang, "erlang", "monotonic_time")
pub fn now() -> Int

@external(erlang, "erlang", "convert_time_unit")
pub fn convert_time_unit(a: Int, b: TimeUnit, c: TimeUnit) -> Int
