import sprocket/internal/utils/uuid

pub opaque type Unique {
  Unique(id: String)
}

pub fn new() -> Unique {
  let assert Ok(id) = uuid.v4()

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
