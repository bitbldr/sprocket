import gleam/int
import gleam/list
import gleam/option.{None, Option, Some}
import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/hooks.{WithDeps, dep}
import sprocket/hooks/reducer.{State, reducer}
import sprocket/hooks/callback.{callback}
import sprocket/identifiable_callback.{CallbackFn}
import sprocket/html.{a, div, span, text}
import sprocket/html/attribute.{class, classes}
import docs/components/search_bar.{SearchBarProps, search_bar}

pub type Page {
  Page(title: String, href: String)
}

type Model {
  Model(show: Bool, active: String, search_filter: Option(String))
}

type Msg {
  NoOp
  SetActive(String)
  SetSearchFilter(Option(String))
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> model
    SetActive(active) -> Model(..model, active: active)
    SetSearchFilter(search_filter) ->
      Model(..model, search_filter: search_filter)
  }
}

fn initial() -> Model {
  Model(show: True, active: "/", search_filter: None)
}

pub type SidebarProps {
  SidebarProps(pages: List(Page))
}

pub fn sidebar(socket: Socket, props) {
  let SidebarProps(pages: pages) = props

  use
    socket,
    State(
      Model(show: show, active: active, search_filter: search_filter),
      dispatch,
    )
  <- reducer(socket, initial(), update)

  render(
    socket,
    case show {
      True -> [
        div(
          [class("border-r border-gray-200 p-2 w-[20rem]")],
          [
            component(
              search_bar,
              SearchBarProps(on_search: fn(query) {
                case query {
                  "" -> dispatch(SetSearchFilter(None))
                  _ -> dispatch(SetSearchFilter(Some(query)))
                }
              }),
            ),
            ..case search_filter {
              Some(query) -> [
                div(
                  [],
                  [
                    span([class("bold italic")], [text("No results for: ")]),
                    span([], [text(query)]),
                  ],
                ),
              ]
              None ->
                list.index_map(
                  pages,
                  fn(i, page) {
                    component(
                      link,
                      LinkProps(
                        int.to_string(i + 1) <> ". " <> page.title,
                        page.href,
                        page.href == active,
                        CallbackFn(fn() {
                          dispatch(SetActive(page.href))
                          Nil
                        }),
                      ),
                    )
                  },
                )
            }
          ],
        ),
      ]
      False -> []
    },
  )
}

type LinkProps {
  LinkProps(title: String, href: String, is_active: Bool, on_click: CallbackFn)
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
