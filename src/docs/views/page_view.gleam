import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/html.{body, div, head, html, link, script}
import sprocket/html/attribute.{
  class, crossorigin, href, integrity, lang, referrerpolicy, rel, src,
}
import docs/components/header.{HeaderProps, MenuItem, header}
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
          head(
            [],
            [
              link([rel("stylesheet"), href("/app.css")]),
              link([
                rel("stylesheet"),
                href(
                  "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.2.1/css/all.min.css",
                ),
                integrity(
                  "sha512-MV7K8+y+gLIBoVD59lQIYicR65iaqukzvf/nwasF0nqhPay5w/9lJmVM2hMDcnK1OnMGCdVK+iQrJ7lzPJQd1w==",
                ),
                crossorigin("anonymous"),
                referrerpolicy("no-referrer"),
              ]),
            ],
          ),
          body(
            [
              class(
                "bg-white dark:bg-gray-900 dark:text-white flex flex-col h-screen",
              ),
            ],
            [
              div(
                [],
                [
                  component(
                    header,
                    HeaderProps(menu_items: [
                      MenuItem(
                        "Github",
                        "https://github.com/eliknebel/sprocket",
                      ),
                    ]),
                  ),
                ],
              ),
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
