import gleam/erlang/process.{type Subject}
import sprocket/internal/utils/cuid

pub opaque type Unique(kind) {
  Unique(id: String)
}

pub fn cuid(channel: Subject(cuid.Message)) -> Unique(kind) {
  let id = cuid.generate(channel)

  Unique(id: id)
}

pub fn slug(channel: Subject(cuid.Message), label: String) -> Unique(kind) {
  let id = label <> "-" <> cuid.slug(channel)

  Unique(id: id)
}

pub fn from_string(str: String) -> Unique(kind) {
  Unique(id: str)
}

pub fn to_string(unique: Unique(kind)) -> String {
  unique.id
}

pub fn equals(a: Unique(kind), b: Unique(kind)) -> Bool {
  a.id == b.id
}
