import gleeunit/should
import sprocket/internal/context.{Changed, Unchanged, compare_deps}
import sprocket/internal/utils/common.{dynamic_from}

// gleeunit test functions end in `_test`
pub fn compare_empty_deps_test() {
  compare_deps([], [])
  |> should.equal(Unchanged)
}

pub fn compare_same_deps_test() {
  compare_deps([dynamic_from("one")], [dynamic_from("one")])
  |> should.equal(Unchanged)
}

pub fn compare_different_deps_test() {
  compare_deps([dynamic_from("one")], [dynamic_from("two")])
  |> should.equal(Changed([dynamic_from("two")]))
}
