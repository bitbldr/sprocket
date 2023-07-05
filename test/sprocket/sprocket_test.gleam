import gleam/dynamic
import gleeunit/should
import sprocket/hooks.{Changed, Unchanged, compare_deps}

// gleeunit test functions end in `_test`
pub fn compare_empty_deps_test() {
  compare_deps([], [])
  |> should.equal(Unchanged)
}

pub fn compare_same_deps_test() {
  compare_deps([dynamic.from("one")], [dynamic.from("one")])
  |> should.equal(Unchanged)
}

pub fn compare_different_deps_test() {
  compare_deps([dynamic.from("one")], [dynamic.from("two")])
  |> should.equal(Changed([dynamic.from("two")]))
}
