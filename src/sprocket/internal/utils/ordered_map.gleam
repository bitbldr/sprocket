import gleam/list
import gleam/map.{type Map}

pub type KeyedItem(k, a) {
  KeyedItem(key: k, value: a)
}

pub opaque type OrderedMap(k, a) {
  OrderedMap(ordered: List(KeyedItem(k, a)), map: Map(k, a), size: Int)
}

pub opaque type OrderedMapIter(k, a) {
  OrderedMapIter(ordered: List(KeyedItem(k, a)))
}

pub fn new() -> OrderedMap(k, a) {
  OrderedMap(ordered: [], map: map.new(), size: 0)
}

pub fn from(
  ordered: List(KeyedItem(k, a)),
  map: Map(k, a),
  size: Int,
) -> OrderedMap(k, a) {
  OrderedMap(ordered, map, size)
}

pub fn from_list(ordered: List(KeyedItem(k, a))) -> OrderedMap(k, a) {
  let #(r_ordered, map, size) =
    ordered
    |> list.fold(
      #([], map.new(), 0),
      fn(acc, keyed_item) {
        let #(ordered, map, size) = acc
        let KeyedItem(key, value) = keyed_item

        let keyed_item = KeyedItem(key, value)
        case map.has_key(map, key) {
          True -> #(ordered, map, size)
          False -> #(
            [keyed_item, ..ordered],
            map.insert(map, key, value),
            size + 1,
          )
        }
      },
    )

  OrderedMap(list.reverse(r_ordered), map, size)
}

pub fn insert(m: OrderedMap(k, a), key: k, value: a) -> OrderedMap(k, a) {
  // TODO: This insertion could probably be more efficient than 2n
  OrderedMap(
    ordered: list.reverse([KeyedItem(key, value), ..list.reverse(m.ordered)]),
    map: map.insert(m.map, key, value),
    size: m.size + 1,
  )
}

pub fn update(m: OrderedMap(k, a), key: k, value: a) -> OrderedMap(k, a) {
  case map.has_key(m.map, key) {
    True ->
      OrderedMap(
        ordered: list.map(
          m.ordered,
          fn(keyed_item) {
            let KeyedItem(k, _v) = keyed_item
            case k == key {
              True -> KeyedItem(key, value)
              False -> keyed_item
            }
          },
        ),
        map: map.insert(m.map, key, value),
        size: m.size,
      )
    False -> m
  }
}

pub fn has_key(m: OrderedMap(k, a), key: k) -> Bool {
  map.has_key(m.map, key)
}

pub fn get(m: OrderedMap(k, a), key: k) -> Result(a, Nil) {
  map.get(m.map, key)
}

pub fn remove(m: OrderedMap(k, a), key: k) -> OrderedMap(k, a) {
  case map.has_key(m.map, key) {
    True ->
      OrderedMap(
        ordered: m.ordered,
        map: map.delete(m.map, key),
        size: m.size - 1,
      )
    False -> m
  }
}

pub fn size(m: OrderedMap(k, a)) -> Int {
  m.size
}

pub fn iter(m: OrderedMap(k, a)) -> OrderedMapIter(k, a) {
  m.ordered
  |> OrderedMapIter
}

pub fn next(
  iter: OrderedMapIter(k, a),
) -> Result(#(OrderedMapIter(k, a), KeyedItem(k, a)), Nil) {
  case iter {
    OrderedMapIter(ordered: []) -> Error(Nil)
    OrderedMapIter(ordered: [item, ..rest]) -> Ok(#(OrderedMapIter(rest), item))
  }
}

/// Folds over the map, passing each item to the given function.
pub fn fold(m: OrderedMap(k, a), acc: b, func: fn(b, KeyedItem(k, a)) -> b) -> b {
  m.ordered
  |> list.fold(acc, func)
}

/// Maps over the map, passing each item to the given function.
pub fn map(m: OrderedMap(k, a), func: fn(KeyedItem(k, a)) -> c) -> List(c) {
  m.ordered
  |> list.map(func)
}

/// Maps over the map, passing the index of each item to the given function.
pub fn index_map(
  m: OrderedMap(k, a),
  func: fn(Int, KeyedItem(k, a)) -> c,
) -> List(c) {
  m.ordered
  |> list.index_map(func)
}

/// Returns the next item from key in the ordered map, if it exists.
pub fn find_next(m: OrderedMap(k, a), key: k) -> Result(a, Nil) {
  case m.ordered {
    [] -> Error(Nil)
    [item, ..rest] ->
      case item {
        KeyedItem(k, _v) ->
          case k == key {
            True -> find_next_helper(rest)
            False -> find_next(OrderedMap(rest, m.map, m.size), key)
          }
      }
  }
}

fn find_next_helper(ordered: List(KeyedItem(k, a))) -> Result(a, Nil) {
  case ordered {
    [item, ..] -> Ok(item.value)
    _ -> Error(Nil)
  }
}

/// Returns the previous item from key in the ordered map, if it exists.
pub fn find_previous(m: OrderedMap(k, a), key: k) -> Result(a, Nil) {
  find_previous_helper(m, key, Error(Nil))
}

fn find_previous_helper(
  m: OrderedMap(k, a),
  key: k,
  prev: Result(a, Nil),
) -> Result(a, Nil) {
  case m.ordered {
    [] -> Error(Nil)
    [item, ..rest] ->
      case item {
        KeyedItem(k, v) ->
          case k == key {
            True -> prev
            False ->
              find_previous_helper(OrderedMap(rest, m.map, m.size), key, Ok(v))
          }
      }
  }
}

pub fn find(
  m: OrderedMap(k, a),
  find_by: fn(KeyedItem(k, a)) -> Bool,
) -> Result(KeyedItem(k, a), Nil) {
  case m.ordered {
    [] -> Error(Nil)
    [item, ..rest] ->
      case item {
        KeyedItem(k, v) ->
          case find_by(item) {
            True -> Ok(KeyedItem(k, v))
            False -> find(OrderedMap(rest, m.map, m.size), find_by)
          }
      }
  }
}
