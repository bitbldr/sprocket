import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/html.{body, div, head, html, link, script}
import sprocket/html/attribute.{class, href, lang, rel, src}
import docs/components/sidebar.{Page, SidebarProps, sidebar}
import docs/components/pages/introduction.{
  IntroductionPageProps, introduction_page,
}

pub type PageViewProps {
  PageViewProps(route: String)
}

pub fn page_view(socket: Socket, props: PageViewProps) {
  let PageViewProps(route: route) = props

  let pages = [Page("Introduction", "/"), Page("Components", "/components")]

  let #(page_component, page_props) = case route {
    "/" -> #(introduction_page, IntroductionPageProps)
    _ -> #(introduction_page, IntroductionPageProps)
  }

  render(
    socket,
    [
      html(
        [lang("en")],
        [
          head([], [link([rel("stylesheet"), href("/app.css")])]),
          body(
            [
              class(
                "bg-white dark:bg-gray-900 dark:text-white flex flex-col h-screen",
              ),
            ],
            [
              div(
                [class("flex-1 flex flex-row")],
                [
                  component(sidebar, SidebarProps(pages)),
                  component(page_component, page_props),
                ],
              ),
              script([src("/client.js")], []),
            ],
          ),
        ],
      ),
    ],
  )
}
