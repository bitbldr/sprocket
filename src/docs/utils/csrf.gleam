import gleam/bit_string
import gleam/crypto.{Sha256}
import sprocket/html.{meta}
import sprocket/html/attributes.{content, name}

pub fn generate(secret_key_base: String) {
  crypto.strong_random_bytes(26)
  |> crypto.sign_message(bit_string.from_string(secret_key_base), Sha256)
}

pub fn validate(csrf_token: String, secret_key_base: String) {
  case
    crypto.verify_signed_message(
      csrf_token,
      bit_string.from_string(secret_key_base),
    )
  {
    Ok(token) -> Ok(token)
    Error(_) -> Error("Invalid CSRF token")
  }
}
