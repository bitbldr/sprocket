pub type TimeUnit {
  Second
  Millisecond
  Microsecond
  Nanosecond
}

/// Returns the current OS system time.
///
/// <https://erlang.org/doc/apps/erts/time_correction.html#OS_System_Time>
@external(erlang, "os", "system_time")
pub fn system_time(a: TimeUnit) -> Int
