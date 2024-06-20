import gleam/erlang/process.{type Subject}
import gleam/result
import ids/cuid
import ids/uuid
import sprocket/internal/logger

pub opaque type Unique {
  Unique(id: String)
}

pub fn uuid() -> Unique {
  let assert Ok(id) =
    uuid.generate_v4()
    |> result.map_error(fn(error) {
      logger.error("unique.uuid: failed to generate UUID")
      error
    })

  Unique(id: id)
}

pub fn cuid(channel: Subject(cuid.Message)) -> Unique {
  let id = cuid.generate(channel)

  Unique(id: id)
}

pub fn slug(channel: Subject(cuid.Message), label: String) -> Unique {
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
