import gleam/map.{Map}

/// Takes a string and a map of interpolations and returns a new string with the
/// interpolations applied.
/// 
/// Example:
/// ```
///   let assert "Hello World!" = "Hello {name}!" |> s_strfmt({"name": "World"})
/// ```
pub fn s_strfmt(str: String, interpolations: Map(String, String)) {
  todo
}
