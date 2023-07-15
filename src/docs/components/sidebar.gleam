import gleam/int
import gleam/list
import gleam/option.{None, Option, Some}
import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/hooks/reducer.{State, reducer}
import sprocket/html.{a, aside, div, keyed, text}
import sprocket/html/attribute.{class, classes, id}
import docs/utils/common.{maybe}
import docs/components/search_bar.{SearchBarProps, search_bar}
import docs/page_route.{PageRoute}

pub type Page {
  Page(title: String, route: PageRoute)
}

type Model {
  Model(show: Bool, search_filter: Option(String))
}

type Msg {
  NoOp
  SetSearchFilter(Option(String))
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> model
    SetSearchFilter(search_filter) ->
      Model(..model, search_filter: search_filter)
  }
}

fn initial() -> Model {
  Model(show: True, search_filter: None)
}

pub type SidebarProps {
  SidebarProps(pages: List(Page), active: PageRoute)
}

pub fn sidebar(socket: Socket, props) {
  let SidebarProps(pages: pages, active: active) = props

  use socket, State(Model(show: show, search_filter: search_filter), dispatch) <- reducer(
    socket,
    initial(),
    update,
  )

  render(
    socket,
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
              div([class("font-bold italic my-1")], [text("No results for: ")]),
              div([], [text(query)]),
            ],
          ),
        ]
        None ->
          list.index_map(
            pages,
            fn(i, page) {
              keyed(
                page.title,
                component(
                  link,
                  LinkProps(
                    int.to_string(i + 1) <> ". " <> page.title,
                    page_route.href(page.route),
                    page.route == active,
                  ),
                ),
              )
            },
          )
      }
    ],
  )
}

type LinkProps {
  LinkProps(title: String, href: String, is_active: Bool)
}

fn link(socket: Socket, props: LinkProps) {
  let LinkProps(title: title, href: href, is_active: is_active) = props

  render(
    socket,
    [
      a(
        [
          classes([
            Some("block p-2 text-blue-500 hover:text-blue-700"),
            maybe(is_active, "font-bold"),
          ]),
          attribute.href(href),
        ],
        [text(title)],
      ),
    ],
  )
}
