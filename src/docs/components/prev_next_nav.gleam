import gleam/option.{Some}
import gleam/result
import sprocket/context.{Context}
import sprocket/component.{component, render}
import sprocket/html.{a, div, hr, i, text}
import sprocket/html/attributes.{class, classes}
import sprocket/internal/utils/ordered_map.{OrderedMap}
import docs/utils/common.{maybe}
import docs/page_route.{Page, PageRoute}

pub type PrevNextNavProps {
  PrevNextNavProps(pages: OrderedMap(PageRoute, Page), active: PageRoute)
}

pub fn prev_next_nav(ctx: Context, props) {
  let PrevNextNavProps(pages: pages, active: active) = props

  let prev_page = ordered_map.find_previous(pages, active)
  let next_page = ordered_map.find_next(pages, active)

  render(
    ctx,
    [
      hr([class("text-gray-500 my-6")]),
      div(
        [class("flex flex-row my-6")],
        [
          component(link, PageLinkProps(prev_page, active, Prev)),
          div([class("flex-1")], []),
          component(link, PageLinkProps(next_page, active, Next)),
        ],
      ),
    ],
  )
}

type NextOrPrev {
  Next
  Prev
}

type PageLinkProps {
  PageLinkProps(
    page: Result(Page, Nil),
    active: PageRoute,
    next_or_prev: NextOrPrev,
  )
}

fn link(ctx: Context, props: PageLinkProps) {
  let PageLinkProps(page: page, active: active, next_or_prev: next_or_prev) =
    props

  page
  |> result.map(fn(page) {
    let title = page.title
    let href = page_route.href(page.route)
    let is_active = page.route == active

    render(
      ctx,
      [
        a(
          [
            classes([
              Some(
                "block py-1.5 px-2 text-blue-500 hover:text-blue-600 active:text-blue-700 no-underline hover:!underline",
              ),
              maybe(is_active, "font-bold"),
            ]),
            attributes.href(href),
          ],
          case next_or_prev {
            Next -> [text(title), next_or_prev_icon(Next)]
            Prev -> [next_or_prev_icon(Prev), text(title)]
          },
        ),
      ],
    )
  })
  |> result.unwrap(render(ctx, []))
}

fn next_or_prev_icon(next_or_prev: NextOrPrev) {
  case next_or_prev {
    Next -> i([class("fa-solid fa-arrow-right ml-3")], [])
    Prev -> i([class("fa-solid fa-arrow-left mr-3")], [])
  }
}
