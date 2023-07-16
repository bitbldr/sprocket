import gleam/int
import gleam/string
import gleam/crypto

pub fn generate() {
  crypto.strong_random_bytes(26)
  |> process_bytes_r
}

fn process_bytes_r(b: BitString) {
  case b {
    <<>> -> ""
    <<a:8, rest:bit_string>> -> {
      int.to_base16(a)
      |> string.lowercase <> process_bytes_r(rest)
    }
  }
}

pub fn validate(token1: String, token2: String) {
  case token1 == token2 {
    True -> Ok(Nil)
    False -> Error("Invalid CSRF token")
  }
}
