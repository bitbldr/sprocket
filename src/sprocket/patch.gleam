import gleam/list
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedText,
}

pub type Patch {
  Update(
    attrs: Option(List(RenderedAttribute)),
    children: Option(List(#(Int, Patch))),
  )
  Replace(el: RenderedElement)
  Change(text: String)
  From(index: Int, patch: Patch)
  NoOp
}

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

fn compare_attributes(
  old_attributes: List(RenderedAttribute),
  new_attributes: List(RenderedAttribute),
) -> Option(List(RenderedAttribute)) {
  case old_attributes, new_attributes {
    [], [] -> {
      None
    }
    [old_attr, ..rest_old], [new_attr, ..rest_new] -> {
      case old_attr == new_attr {
        True -> {
          compare_attributes(rest_old, rest_new)
        }
        False -> {
          None
        }
      }
    }
    _, _ -> {
      Some(new_attributes)
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

  list.zip(old_children, new_children)
  |> list.index_map(fn(index, zipped) {
    let #(old_child, new_child) = zipped

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
                #(index, From(old_index, child_patch))
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
