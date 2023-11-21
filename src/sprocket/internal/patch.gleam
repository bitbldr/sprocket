import gleam/list
import gleam/string
import gleam/int
import gleam/map.{type Map}
import gleam/option.{type Option, None, Some}
import sprocket/render.{
  type RenderedAttribute, type RenderedElement, RenderedAttribute,
  RenderedClientHook, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedText,
}
import gleam/json.{type Json}
import sprocket/internal/render/json as json_renderer
import sprocket/internal/constants.{EventAttrPrefix, constant}

pub type Patch {
  NoOp
  Update(
    attrs: Option(List(RenderedAttribute)),
    children: Option(List(#(Int, Patch))),
  )
  Replace(el: RenderedElement)
  Insert(el: RenderedElement)
  Remove
  Change(text: String)
  Move(from: Int, patch: Patch)
}

// Creates a diff patch that can be applied to the old element to obtain the new element.
//
// The patch is created by comparing the old and new elements and their children. If the elements
// are the same, the patch will be a NoOp. If the elements are different, the patch will be a
// one of the following:
//  - Replace: the old element should be replaced with the new element
//  - Update: the old element should be updated with the new element's attributes and children
//  - Insert: the new element should be added to the DOM
//  - Remove: the old element should be removed from the DOM
//  - Change: the old element's text should be changed to the new element's text
//  - Move: the old element should be moved to a new position in the DOM
pub fn create(old: RenderedElement, new: RenderedElement) -> Patch {
  case old, new {
    // old and new tags are the same
    RenderedElement(
      tag: old_tag,
      key: old_key,
      attrs: old_attrs,
      children: old_children,
    ), RenderedElement(
      tag: new_tag,
      key: new_key,
      attrs: new_attrs,
      children: new_children,
    ) if old_tag == new_tag -> {
      // check if element has same key
      case old_key == new_key {
        True -> {
          case compare_attributes(old_attrs, new_attrs) {
            Some(attrs) -> {
              Update(
                attrs: Some(attrs),
                children: compare_children(old_children, new_children),
              )
            }
            None -> {
              case compare_children(old_children, new_children) {
                Some(children) -> {
                  Update(attrs: None, children: Some(children))
                }
                None -> {
                  NoOp
                }
              }
            }
          }
        }
        False -> {
          Replace(el: new)
        }
      }
    }
    // old and new components and props are the same
    RenderedComponent(
      fc: old_fc,
      key: _old_key,
      props: old_props,
      hooks: _old_hooks,
      children: old_children,
    ), RenderedComponent(
      fc: new_fc,
      key: _key,
      props: new_props,
      hooks: _hooks,
      children: new_children,
    ) if old_fc == new_fc && old_props == new_props -> {
      // functional components and props are the same, check and children
      case compare_children(old_children, new_children) {
        Some(children) -> {
          Update(attrs: None, children: Some(children))
        }
        None -> {
          NoOp
        }
      }
    }
    // text nodes
    RenderedText(text: old_text), RenderedText(text: new_text) -> {
      case old_text == new_text {
        True -> {
          // nodes are the same
          NoOp
        }
        False -> {
          Change(text: new_text)
        }
      }
    }
    // everything is different
    _, _ -> {
      Replace(el: new)
    }
  }
}

// Takes a list of old and new attributes and optionally returns a list of the new attributes if at
// least one attribute has changed. If no attributes have changed, None is returned.
//
// TODO: This implementation could be optimized to return a diff of changed attributes. For now, we
// return all attributes if at least one attribute has changed.
fn compare_attributes(
  old_attributes: List(RenderedAttribute),
  new_attributes: List(RenderedAttribute),
) -> Option(List(RenderedAttribute)) {
  compare_attributes_helper(build_attrs_map(old_attributes), new_attributes)
}

// Helper function takes a list of old and new attributes and optionally returns a list of changed
// attributes. Since this function is called recursively, it takes a map of old attributes keyed by
// their name to make it easier to lookup the old attribute by name. If the attribute is not found
// in the map, it is considered new. If the attribute is found in the map, it is compared to the new
// attribute to see if it has changed.
//
// If the function returns Some, it means that at least one attribute has changed and the list of
// all attributes is returned. At the root of the recursion, the function will return all attributes
// if at least one attribute has changed, or None if no attributes have changed.
fn compare_attributes_helper(
  old_attributes: Map(String, RenderedAttribute),
  new_attributes: List(RenderedAttribute),
) -> Option(List(RenderedAttribute)) {
  case new_attributes {
    [new_attr, ..rest_new] -> {
      // lookup the old attribute by key, since its position in the list may have changed
      case map.get(old_attributes, attr_key(new_attr)) {
        Ok(old_attr) -> {
          case old_attr == new_attr {
            True -> {
              case
                compare_attributes_helper(
                  map.delete(old_attributes, attr_key(old_attr)),
                  rest_new,
                )
              {
                Some(_) -> {
                  Some(new_attributes)
                }
                None -> {
                  None
                }
              }
            }
            False -> {
              Some(new_attributes)
            }
          }
        }
        _ -> {
          Some(new_attributes)
        }
      }
    }
    _ -> {
      case map.size(old_attributes), list.length(new_attributes) {
        0, 0 -> {
          None
        }
        old_size, new_size if old_size > new_size -> {
          // some attributes have been removed
          Some(new_attributes)
        }
      }
    }
  }
}

fn attr_key(attribute) {
  case attribute {
    RenderedAttribute(name: name, ..) -> {
      name
    }
    RenderedEventHandler(id: id, ..) -> {
      id
    }
    RenderedClientHook(id: id, ..) -> {
      id
    }
  }
}

fn build_attrs_map(attributes) {
  attributes
  |> list.fold(
    map.new(),
    fn(acc, attr) { map.insert(acc, attr_key(attr), attr) },
  )
}

fn build_key_map(
  children: List(RenderedElement),
) -> Map(String, #(Int, RenderedElement)) {
  children
  |> list.index_fold(
    map.new(),
    fn(acc, child, index) {
      case child {
        RenderedElement(key: Some(key), ..) -> {
          map.insert(acc, key, #(index, child))
        }
        _ -> {
          acc
        }
      }
    },
  )
}

fn compare_child_at_index(
  acc: Map(Int, Patch),
  old_children,
  new_child,
  index,
) -> Map(Int, Patch) {
  case list.at(old_children, index) {
    Ok(old_child) -> {
      case create(old_child, new_child) {
        NoOp -> {
          acc
        }
        patch -> {
          map.insert(acc, index, patch)
        }
      }
    }
    Error(Nil) -> {
      map.insert(acc, index, Insert(new_child))
    }
  }
}

// takes a list of old and new children and optionally returns a list of tuples
// of the index and the diff for the children that have changed. This function will
// use the key of the children to determine if they are the same or not regardless
// of their position in the list.
fn compare_children(
  old_children: List(RenderedElement),
  new_children: List(RenderedElement),
) -> Option(List(#(Int, Patch))) {
  let old_key_map = build_key_map(old_children)
  let new_key_map = build_key_map(new_children)

  // determine removed children. some of these results will actually be moves
  // or replaces, but the next step will update those accordingly
  let removals =
    zip_all(old_children, new_children)
    |> list.index_fold(
      map.new(),
      fn(acc, child, index) {
        case child {
          #(
            Some(RenderedElement(key: Some(old_key), ..)),
            Some(RenderedElement(key: Some(_key), ..)),
          ) -> {
            // if both children have keys, then we can check if the key exists in the new key map
            case map.get(new_key_map, old_key) {
              Ok(_) -> {
                // key exists in the new key map so the child has not been removed
                acc
              }
              Error(Nil) -> {
                // key does not exist in the new key map, so the child has been removed
                map.insert(acc, index, Remove)
              }
            }
          }
          #(_, None) -> {
            // This is a case where the new children list is shorter than the old which
            // means that the last child in the old list has either been moved or removed.
            // In either case, this indicates the end of the list so we want to remove
            map.insert(acc, index, Remove)
          }
          _ -> {
            // we can't determine if this child has been removed or not, so just continue
            acc
          }
        }
      },
    )

  new_children
  |> list.index_fold(
    removals,
    fn(acc, new_child, index) {
      case new_child {
        // check if element has a key
        RenderedElement(key: Some(key), ..) -> {
          // check if it exists in the key map
          case map.get(old_key_map, key) {
            Ok(found) -> {
              let #(old_index, old_child) = found

              let child_patch = create(old_child, new_child)

              case index == old_index {
                True -> {
                  // if the index is the same, then the element has not moved
                  map.insert(acc, index, child_patch)
                }
                False -> {
                  map.insert(acc, index, Move(old_index, child_patch))
                }
              }
            }
            Error(Nil) -> {
              compare_child_at_index(acc, old_children, new_child, index)
            }
          }
        }
        _ -> {
          // theres no key, so we want to do a best effort approach here and try to compare
          // the children without keys based on their position in the list
          compare_child_at_index(acc, old_children, new_child, index)
        }
      }
    },
  )
  |> map.filter(fn(_k, child_el) {
    case child_el {
      NoOp -> False
      _ -> True
    }
  })
  |> fn(diff_map) {
    case map.size(diff_map) > 0 {
      True -> {
        Some(map.to_list(diff_map))
      }
      False -> {
        None
      }
    }
  }
}

// Takes a list of old and new children and zips them together as Option. If one list is longer than
// the other, the remaining elements of the shorter list will be None.
fn zip_all(a: List(a), b: List(b)) -> List(#(Option(a), Option(b))) {
  case a, b {
    [], [] -> {
      []
    }
    [a, ..rest_a], [b, ..rest_b] -> {
      [#(Some(a), Some(b)), ..zip_all(rest_a, rest_b)]
    }
    [a, ..rest_a], [] -> {
      [#(Some(a), None), ..zip_all(rest_a, [])]
    }
    [], [b, ..rest_b] -> {
      [#(None, Some(b)), ..zip_all([], rest_b)]
    }
  }
}

pub fn op_code(op: Patch, debug: Bool) -> String {
  case debug {
    True ->
      case op {
        NoOp -> {
          "NoOp"
        }
        Update(..) -> {
          "Update"
        }
        Replace(..) -> {
          "Replace"
        }
        Insert(..) -> {
          "Insert"
        }
        Remove -> {
          "Remove"
        }
        Change(..) -> {
          "Change"
        }
        Move(..) -> {
          "Move"
        }
      }
    False ->
      case op {
        NoOp -> {
          "0"
        }
        Update(..) -> {
          "1"
        }
        Replace(..) -> {
          "2"
        }
        Insert(..) -> {
          "3"
        }
        Remove -> {
          "4"
        }
        Change(..) -> {
          "5"
        }
        Move(..) -> {
          "6"
        }
      }
  }
}

pub fn patch_to_json(patch: Patch, debug: Bool) -> Json {
  case patch {
    NoOp -> {
      json.preprocessed_array([json.string(op_code(patch, debug))])
    }
    Update(attrs, children) -> {
      json.preprocessed_array([
        json.string(op_code(patch, debug)),
        json.nullable(attrs, of: attrs_to_json),
        json.nullable(children, of: children_to_json(_, debug)),
      ])
    }
    Replace(el) -> {
      json.preprocessed_array([
        json.string(op_code(patch, debug)),
        json_renderer.renderer().render(el),
      ])
    }
    Insert(el) -> {
      json.preprocessed_array([
        json.string(op_code(patch, debug)),
        json_renderer.renderer().render(el),
      ])
    }
    Remove -> {
      json.preprocessed_array([json.string(op_code(patch, debug))])
    }
    Change(text) -> {
      json.preprocessed_array([
        json.string(op_code(patch, debug)),
        json.string(text),
      ])
    }
    Move(index, move_patch) -> {
      json.preprocessed_array([
        json.string(op_code(patch, debug)),
        json.int(index),
        patch_to_json(move_patch, debug),
      ])
    }
  }
}

fn attrs_to_json(attrs: List(RenderedAttribute)) -> Json {
  attrs
  |> list.flat_map(fn(attr) {
    case attr {
      RenderedAttribute(name, value) -> {
        [#(name, json.string(value))]
      }
      RenderedEventHandler(kind, id) -> {
        [
          #(
            string.concat([constant(EventAttrPrefix), "-", kind]),
            json.string(id),
          ),
        ]
      }
      RenderedClientHook(name, id) -> {
        [
          #(constant(EventAttrPrefix), json.string(name)),
          #(string.concat([constant(EventAttrPrefix), "-id"]), json.string(id)),
        ]
      }
    }
  })
  |> json.object()
}

fn children_to_json(children: List(#(Int, Patch)), debug: Bool) -> Json {
  children
  |> list.map(map_key_to_str(_, debug))
  |> json.object()
}

fn map_key_to_str(c: #(Int, Patch), debug: Bool) -> #(String, Json) {
  let #(index, patch) = c
  #(int.to_string(index), patch_to_json(patch, debug))
}

fn map_index_fold(map: Map(a, k), acc: b, fold_fn: fn(b, k, a, Int) -> b) {
  map
  |> map.fold(
    #(acc, 0),
    fn(acc, item, key) {
      let #(acc, index) = acc
      #(fold_fn(acc, key, item, index), index + 1)
    },
  )
}
