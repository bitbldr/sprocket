import gleam/io
import gleam/list
import gleam/int
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedKey, RenderedText,
}
import gleam/json.{Json}
import sprocket/render/json as json_renderer

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
    RenderedComponent(fc: old_fc, props: old_props, children: old_children), RenderedComponent(
      fc: new_fc,
      props: new_props,
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
    RenderedKey(key: key) -> {
      key
    }
    RenderedEventHandler(id: id, ..) -> {
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

// takes a list of old and new children and optionally returns a list of tuples
// of the index and the diff for the children that have changed. This function will
// use the key of the children to determine if they are the same or not regardless
// of their position in the list.
fn compare_children(
  old_children: List(RenderedElement),
  new_children: List(RenderedElement),
) -> Option(List(#(Int, Patch))) {
  let key_map: Map(String, #(Int, RenderedElement)) =
    old_children
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

  zip_all(old_children, new_children)
  |> list.index_map(fn(index, zipped) {
    let #(old_child, new_child) = zipped

    case old_child, new_child {
      Some(old_child), Some(new_child) -> {
        case old_child, new_child {
          RenderedElement(..), RenderedElement(key: Some(key), ..) -> {
            // check if element has a key and if it does, check if it exists in the key map
            case map.get(key_map, key) {
              Ok(found) -> {
                let #(old_index, old_child) = found

                let child_patch = create(old_child, new_child)

                case index == old_index {
                  True -> {
                    // if the index is the same, then the element has not moved
                    #(index, child_patch)
                  }
                  False -> {
                    #(index, Move(old_index, child_patch))
                  }
                }
              }
              Error(Nil) -> {
                #(index, create(old_child, new_child))
              }
            }
          }
          _, _ -> {
            #(index, create(old_child, new_child))
          }
        }
      }
      None, Some(new_child) -> {
        case new_child {
          RenderedElement(key: Some(key), ..) -> {
            // check if element has a key and if it does, check if it exists in the key map
            case map.get(key_map, key) {
              Ok(found) -> {
                let #(old_index, old_child) = found
                #(index, Move(old_index, create(old_child, new_child)))
              }
              Error(Nil) -> {
                #(index, Insert(new_child))
              }
            }
          }
          _ -> {
            // new child
            #(index, Insert(new_child))
          }
        }
      }
      Some(_), _ -> {
        // child removed
        #(index, Remove)
      }
    }
  })
  |> list.filter_map(fn(child_el) {
    case child_el {
      #(_index, NoOp) -> Error(Nil)
      #(index, patch) -> Ok(#(index, patch))
    }
  })
  |> fn(diff_list) {
    case diff_list {
      [] -> {
        None
      }
      _ -> {
        Some(diff_list)
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

fn op_code(op: Patch) -> Int {
  case op {
    NoOp -> {
      0
    }
    Update(..) -> {
      1
    }
    Replace(..) -> {
      2
    }
    Insert(..) -> {
      3
    }
    Remove -> {
      4
    }
    Change(..) -> {
      5
    }
    Move(..) -> {
      6
    }
  }
}

pub fn patch_to_json(patch: Patch) -> Json {
  case patch {
    NoOp -> {
      json.preprocessed_array([json.int(op_code(patch))])
    }
    Update(attrs, children) -> {
      json.preprocessed_array([
        json.int(op_code(patch)),
        json.nullable(attrs, of: attrs_to_json),
        json.nullable(children, of: children_to_json),
      ])
    }
    Replace(el) -> {
      json.preprocessed_array([
        json.int(op_code(patch)),
        json_renderer.renderer().render(el),
      ])
    }
    Insert(el) -> {
      json.preprocessed_array([
        json.int(op_code(patch)),
        json_renderer.renderer().render(el),
      ])
    }
    Remove -> {
      json.preprocessed_array([json.int(op_code(patch))])
    }
    Change(text) -> {
      json.preprocessed_array([json.int(op_code(patch)), json.string(text)])
    }
    Move(index, move_patch) -> {
      json.preprocessed_array([
        json.int(op_code(patch)),
        json.int(index),
        patch_to_json(move_patch),
      ])
    }
  }
}

fn attrs_to_json(attrs: List(RenderedAttribute)) -> Json {
  attrs
  |> list.map(fn(attr) {
    case attr {
      RenderedAttribute(name, value) -> {
        #(name, json.string(value))
      }
      RenderedKey(key) -> {
        #("key", json.string(key))
      }
      RenderedEventHandler(id, event) -> {
        #(id, json.string(event))
      }
    }
  })
  |> json.object()
}

fn children_to_json(children: List(#(Int, Patch))) -> Json {
  children
  |> list.map(map_key_to_str)
  |> json.object()
}

fn map_key_to_str(c: #(Int, Patch)) -> #(String, Json) {
  let #(index, patch) = c
  #(int.to_string(index), patch_to_json(patch))
}
