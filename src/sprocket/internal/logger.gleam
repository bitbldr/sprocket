import gleam/dynamic.{type Dynamic}
import gleam/io

pub type Level {
  Emergency
  Alert
  Critical
  Error
  Warning
  Notice
  Info
  Debug
}

/// Configure the Erlang logger to use the log level and output format that we
/// want, rather than the more verbose Erlang default format.
///
@external(erlang, "sprocket_ffi", "configure_logger_backend")
pub fn configure_backend() -> Nil

@external(erlang, "logger", "log")
fn erlang_log(a: Level, b: String) -> Dynamic

pub fn log(level: Level, message: String) -> Nil {
  erlang_log(level, message)
  Nil
}

pub fn log_meta(level: Level, message: String, meta: a) -> a {
  erlang_log(level, message)

  // TODO: Do something interesting to capture metadata. For now, just log it.
  // This will print regardless of the log level which is an issue.
  io.debug(meta)
}

pub fn info(message: String) -> Nil {
  log(Info, message)
}

pub fn info_meta(message: String, meta: a) -> a {
  log_meta(Info, message, meta)
}

pub fn warn(message: String) -> Nil {
  log(Warning, message)
}

pub fn warn_meta(message: String, meta: a) -> a {
  log_meta(Warning, message, meta)
}

pub fn error(message: String) -> Nil {
  log(Error, message)
}

pub fn error_meta(message: String, meta: a) -> a {
  log_meta(Error, message, meta)
}

pub fn debug(message: String) -> Nil {
  log(Debug, message)
}

pub fn debug_meta(message: String, meta: a) -> a {
  log_meta(Debug, message, meta)
}
