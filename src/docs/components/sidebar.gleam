import gleam/int
import gleam/list
import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/hooks.{WithDeps, dep}
import sprocket/hooks/reducer.{State, reducer}
import sprocket/hooks/callback.{callback}
import sprocket/html.{a, div, text}
import sprocket/html/attribute.{class, classes}
import docs/components/search_bar.{SearchBarProps, search_bar}

pub type Page {
  Page(title: String, href: String)
}

type Model {
  Model(show: Bool, active: String)
}

type Msg {
  NoOp
  SetActive(String)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> model
    SetActive(active) -> Model(..model, active: active)
  }
}

fn initial() -> Model {
  Model(show: True, active: "/")
}

pub type SidebarProps {
  SidebarProps(pages: List(Page))
}

pub fn sidebar(socket: Socket, props) {
  let SidebarProps(pages: pages) = props

  use socket, State(Model(show: show, active: active), dispatch) <- reducer(
    socket,
    initial(),
    update,
  )

  render(
    socket,
    case show {
      True -> [
        div(
          [class("bg-gray-100 dark:bg-gray-800")],
          [
            component(
              search_bar,
              SearchBarProps(on_search: fn(_query) { todo }),
            ),
            ..list.index_map(
              pages,
              fn(i, page) {
                component(
                  link,
                  LinkProps(
                    int.to_string(i + 1) <> ". " <> page.title,
                    page.href,
                    page.href == active,
                    fn() {
                      dispatch(SetActive(page.href))
                      Nil
                    },
                  ),
                )
              },
            )
          ],
        ),
      ]
      False -> []
    },
  )
}

type LinkProps {
  LinkProps(title: String, href: String, is_active: Bool, on_click: fn() -> Nil)
}

fn link(socket: Socket, props: LinkProps) {
  let LinkProps(
    title: title,
    href: _href,
    is_active: is_active,
    on_click: on_click,
  ) = props

  use socket, on_click <- callback(socket, on_click, WithDeps([dep(on_click)]))

  render(
    socket,
    [
      a(
        [
          classes([
            "block p-2 text-blue-500 hover:text-blue-700",
            case is_active {
              True -> "font-bold"
              False -> ""
            },
          ]),
          // attribute.href(href),
          attribute.href("#"),
          attribute.on_click(on_click),
        ],
        [text(title)],
      ),
    ],
  )
}
