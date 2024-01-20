import gleam/io
import gleam/list
import gleam/option.{None, Some}
import ids/cuid
import sprocket/runtime.{type Runtime}
import sprocket/context
import sprocket/render.{
  type RenderedElement, RenderedAttribute, RenderedElement, RenderedEventHandler,
}
import sprocket/html/render as html_render
import sprocket/internal/utils/unique

pub fn live(view) {
  let assert Ok(cuid_channel) = cuid.start()
  let assert Ok(spkt) =
    runtime.start(unique.uuid(), view, cuid_channel, None, None)

  spkt
}

pub fn render_html(spkt) {
  let renderer = html_render.renderer()

  let html =
    runtime.render(spkt)
    |> renderer.render()

  #(spkt, html)
}

pub type Event {
  ClickEvent
}

pub fn render_event(spkt: Runtime, event: Event, html_id: String) {
  case runtime.get_rendered(spkt) {
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
              case runtime.get_handler(spkt, event_id) {
                Ok(context.IdentifiableHandler(_, handler)) -> {
                  // call the event handler
                  handler(None)
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
