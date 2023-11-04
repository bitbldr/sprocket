import gleam/erlang/process.{Subject}
import ids/cuid.{Message}
import ids/uuid

pub opaque type Unique {
  Unique(id: String)
}

pub fn uuid() -> Unique {
  let assert Ok(id) = uuid.generate_v4()

  Unique(id: id)
}

pub fn cuid(channel: Subject(Message)) -> Unique {
  let id = cuid.generate(channel)

  Unique(id: id)
}

pub fn slug(channel: Subject(Message), label: String) -> Unique {
  let id = label <> "-" <> cuid.slug(channel)

  Unique(id: id)
}

pub fn from_string(str: String) -> Unique {
  Unique(id: str)
}

pub fn to_string(unique: Unique) -> String {
  unique.id
}

pub fn equals(a: Unique, b: Unique) -> Bool {
  a.id == b.id
}
