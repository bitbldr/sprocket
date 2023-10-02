import gleam/int
import gleam/option.{None, Option, Some}
import sprocket/context.{Context}
import sprocket/component.{component, render}
import sprocket/hooks/reducer.{reducer}
import sprocket/html.{a, div, keyed, text}
import sprocket/html/attributes.{class, classes}
import sprocket/internal/utils/ordered_map.{KeyedItem, OrderedMap}
import docs/utils/common.{maybe}
import docs/components/search_bar.{SearchBarProps, search_bar}
import docs/page_route.{Page, PageRoute}

type Model {
  Model(search_filter: Option(String))
}

type Msg {
  NoOp
  SetSearchFilter(Option(String))
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    NoOp -> model
    SetSearchFilter(search_filter) -> Model(search_filter: search_filter)
  }
}

fn initial() -> Model {
  Model(search_filter: None)
}

pub type SidebarProps {
  SidebarProps(pages: OrderedMap(PageRoute, Page), active: PageRoute)
}

pub fn sidebar(ctx: Context, props) {
  let SidebarProps(pages: pages, active: active) = props

  use ctx, Model(search_filter: search_filter), dispatch <- reducer(
    ctx,
    initial(),
    update,
  )

  render(
    ctx,
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
          ordered_map.index_map(
            pages,
            fn(i, item) {
              let KeyedItem(_, page) = item

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

fn link(ctx: Context, props: LinkProps) {
  let LinkProps(title: title, href: href, is_active: is_active) = props

  render(
    ctx,
    [
      a(
        [
          classes([
            Some("block p-2 text-blue-500 hover:text-blue-700 hover:underline"),
            maybe(is_active, "font-bold"),
          ]),
          attributes.href(href),
        ],
        [text(title)],
      ),
    ],
  )
}
