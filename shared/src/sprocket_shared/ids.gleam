/// Shared identifier aliases used across BEAM and browser runtimes.
pub type ElementId = String
pub type EventHandlerId = String
pub type HookId = String

/// Normalize an identifier to its string representation (placeholder for future encodings).
pub fn to_string(id: String) -> String {
  id
}

/// Parse an identifier from a string (placeholder for future validation).
pub fn from_string(id: String) -> String {
  id
}
