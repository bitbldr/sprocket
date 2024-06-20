import gleam/io
import gleam/list
import gleam/option.{None, Some}
import sprocket/context.{Updater}
import sprocket/internal/reconcile.{
  type ReconciledElement, ReconciledAttribute, ReconciledElement,
  ReconciledEventHandler,
}
import sprocket/internal/reconcilers/recursive
import sprocket/render.{renderer}
import sprocket/renderers/html.{html_renderer}
import sprocket/runtime.{type Runtime}

pub fn connect(view) {
  let assert Ok(spkt) = runtime.start(view, Updater(fn(_) { Ok(Nil) }), None)

  spkt
}

pub fn render_html(spkt) {
  use render_html <- renderer(html_renderer())

  let html =
    runtime.reconcile_immediate(spkt)
    |> render_html()

  #(spkt, html)
}

pub type Event {
  ClickEvent
}

pub fn render_event(spkt: Runtime, event: Event, html_id: String) {
  case runtime.get_reconciled(spkt) {
    Some(reconciled) -> {
      let found =
        recursive.find(reconciled, fn(el: ReconciledElement) {
          case el {
            ReconciledElement(_tag, _key, attrs, _children) -> {
              // try and find id attr that matches the given id
              let matching_id_attr =
                attrs
                |> list.find(fn(attr) {
                  case attr {
                    ReconciledAttribute("id", id) if id == html_id -> True
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
        })

      case found {
        Ok(ReconciledElement(_tag, _key, attrs, _children)) -> {
          let event_kind = case event {
            ClickEvent -> "click"
          }

          // find click event handler id
          let rendered_event_handler =
            attrs
            |> list.find(fn(attr) {
              case attr {
                ReconciledEventHandler(kind, _id) if kind == event_kind -> True
                _ -> False
              }
            })

          case rendered_event_handler {
            Ok(ReconciledEventHandler(_kind, event_id)) -> {
              case runtime.process_event_immediate(spkt, event_id, None) {
                Ok(_) -> spkt
                _ -> panic
              }
            }
            _ -> {
              io.debug("no event handler")
              panic
            }
          }
        }
        _ -> {
          io.debug("no match")
          panic
        }
      }
    }
    None -> {
      io.debug("no reconciled")
      panic
    }
  }

  spkt
}
