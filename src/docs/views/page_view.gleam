import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/html.{body, div, head, html, link, meta}
import sprocket/html/attribute.{
  charset, class, content, crossorigin, href, integrity, lang, name,
  referrerpolicy, rel,
}
import docs/components/header.{HeaderProps, MenuItem, header}
import docs/components/responsive_drawer.{
  ResponsiveDrawerProps, responsive_drawer,
}
import docs/components/sidebar.{Page, SidebarProps, sidebar}
import docs/components/pages/introduction.{
  IntroductionPageProps, introduction_page,
}
import docs/components/pages/components.{ComponentsPageProps, components_page}
import docs/components/pages/misc.{MiscPageProps, misc_page}
import docs/components/pages/not_found.{NotFoundPageProps, not_found_page}
import docs/page_route.{Components, Introduction, Misc, PageRoute, Unknown}

pub type PageViewProps {
  PageViewProps(route: PageRoute, path_segments: List(String))
}

pub fn page_view(socket: Socket, props: PageViewProps) {
  let PageViewProps(route: route, ..) = props

  let pages = [
    Page("Introduction", Introduction),
    Page("Components", Components),
    Page("Misc.", Misc),
  ]

  render(
    socket,
    [
      html(
        [lang("en")],
        [
          head(
            [],
            [
              meta([charset("utf-8")]),
              meta([
                name("viewport"),
                content("width=device-width, initial-scale=1"),
              ]),
              meta([
                name("description"),
                content(
                  "Sprocket is a framework for building real-time applications in Gleam.",
                ),
              ]),
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
              component(
                responsive_drawer,
                ResponsiveDrawerProps(
                  drawer: component(sidebar, SidebarProps(pages, route)),
                  content: div(
                    [class("container mx-auto px-6")],
                    [
                      case route {
                        Introduction ->
                          component(introduction_page, IntroductionPageProps)
                        Components ->
                          component(components_page, ComponentsPageProps)
                        Misc -> component(misc_page, MiscPageProps)
                        Unknown -> component(not_found_page, NotFoundPageProps)
                      },
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
