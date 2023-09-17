import gleam/io
import gleam/list
import gleam/option.{None, Some}
import sprocket/sprocket.{Sprocket}
import sprocket/context
import sprocket/internal/identifiable_callback.{CallbackFn}
import sprocket/render.{RenderedAttribute,
  RenderedElement, RenderedEventHandler}
import sprocket/internal/render/html as sprocket_render_html
import sprocket/internal/utils/unique

pub fn live(view) {
  sprocket.start(unique.new(), view, None, None)
}

pub fn render_html(spkt) {
  let renderer = sprocket_render_html.renderer()

  let html =
    sprocket.render(spkt)
    |> renderer.render()

  #(spkt, html)
}

pub type Event {
  ClickEvent
}

pub fn render_event(spkt: Sprocket, event: Event, html_id: String) {
  case sprocket.get_rendered(spkt) {
    Some(rendered) -> {
      let found =
        render.find(
          rendered,
          fn(el: RenderedElement) {
            case el {
              RenderedElement(_tag, _key, attrs, _children) -> {
                // try and find id attr that matches the given id
                let matching_id_attr =
                  attrs
                  |> list.find(fn(attr) {
                    case attr {
                      RenderedAttribute("id", id) if id == html_id -> True
                      _ -> False
                    }
                  })

                case matching_id_attr {
                  Ok(_) -> True
                  _ -> False
                }
              }
              _ -> False
            }
          },
        )

      case found {
        Ok(RenderedElement(_tag, _key, attrs, _children)) -> {
          let event_kind = case event {
            ClickEvent -> "click"
          }

          // find click event handler id
          let rendered_event_handler =
            attrs
            |> list.find(fn(attr) {
              case attr {
                RenderedEventHandler(kind, _id) if kind == event_kind -> True
                _ -> False
              }
            })

          case rendered_event_handler {
            Ok(RenderedEventHandler(_kind, event_id)) -> {
              case sprocket.get_handler(spkt, event_id) {
                Ok(context.EventHandler(_, handler)) -> {
                  // call the event handler
                  case handler {
                    CallbackFn(cb) -> {
                      cb()
                    }
                    // CallbackWithValueFn(cb) -> {
                    //   case event.value {
                    //     Some(value) -> cb(value)
                    //     _ -> {
                    //       logger.error("Error decoding event value:")
                    //       io.debug(event)
                    //       panic
                    //     }
                    //   }
                    // }
                    _ -> {
                      todo
                    }
                  }
                }
                _ -> Nil
              }
            }
            _ -> {
              io.debug("no event handler")
              panic
            }
          }
        }
        Error(_) -> {
          io.debug("no match")
          panic
        }
      }
    }
    None -> {
      io.debug("no rendered")
      panic
    }
  }

  spkt
}
