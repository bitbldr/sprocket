import gleam/list
import gleam/map.{Map}

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

pub fn fold(m: OrderedMap(k, a), acc: b, func: fn(b, KeyedItem(k, a)) -> b) -> b {
  m.ordered
  |> list.fold(acc, func)
}
