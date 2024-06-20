pub fn element_at(list: List(a), index: Int, start curr: Int) -> Result(a, Nil) {
  case list {
    [] -> Error(Nil)
    [el, ..rest] -> {
      case curr == index {
        True -> Ok(el)
        False -> element_at(rest, index, curr + 1)
      }
    }
  }
}
