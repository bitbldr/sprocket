import gleam/list
import gleam/string
import sprocket/context.{Context}
import sprocket/component.{component, render}
import sprocket/html.{a, div, i, span, text}
import sprocket/html/attributes.{class, href}

pub type MenuItem {
  MenuItem(label: String, href: String)
}

pub type HeaderProps {
  HeaderProps(menu_items: List(MenuItem))
}

pub fn header(ctx: Context, props) {
  let HeaderProps(menu_items: menu_items) = props

  render(
    ctx,
    [
      div(
        [
          class(
            "flex flex-row justify-between border-b border-gray-200 dark:border-gray-600 min-h-[60px]",
          ),
        ],
        [
          a(
            [href("/")],
            [
              div(
                [class("p-2 mx-2")],
                [
                  div(
                    [class("italic bold text-2xl")],
                    [text("⚙️ Sprocket")],
                  ),
                  div(
                    [class("text-gray-500 text-sm")],
                    [text("Real-time server components in Gleam ✨")],
                  ),
                ],
              ),
            ],
          ),
          div(
            [],
            list.map(
              menu_items,
              fn(item) { component(menu_item, MenuItemProps(item)) },
            ),
          ),
        ],
      ),
    ],
  )
}

type MenuItemProps {
  MenuItemProps(item: MenuItem)
}

fn menu_item(ctx: Context, props: MenuItemProps) {
  let MenuItemProps(item: MenuItem(label: label, href: href)) = props

  let is_external = is_external_href(href)

  render(
    ctx,
    [
      a(
        [
          class("block p-5 border-b-2 border-transparent hover:border-blue-500"),
          attributes.href(href),
          ..case is_external {
            True -> [attributes.target("_blank")]
            False -> []
          }
        ],
        [
          text(label),
          ..case is_external {
            True -> [
              span(
                [class("text-gray-500 text-sm ml-2")],
                [i([class("fa-solid fa-arrow-up-right-from-square")], [])],
              ),
            ]
            False -> []
          }
        ],
      ),
    ],
  )
}

fn is_external_href(href: String) -> Bool {
  string.starts_with(href, "http://") || string.starts_with(href, "https://")
}
