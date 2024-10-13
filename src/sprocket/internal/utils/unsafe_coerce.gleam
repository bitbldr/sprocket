import gleam/dynamic.{type Dynamic}

// there are certain cases where we need to coerce a Dynamic to a specific type
// this function is unsafe and should be used with caution
pub fn unsafe_coerce(a: Dynamic) -> anything {
  do_unsafe_coerce(a)
}

@external(erlang, "gleam_stdlib", "identity")
@external(javascript, "../gleam_stdlib.mjs", "identity")
fn do_unsafe_coerce(a: Dynamic) -> a
