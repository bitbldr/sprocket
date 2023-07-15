import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/html.{body, button, div, head, html, i, link, meta}
import sprocket/html/attribute.{
  charset, class, content, crossorigin, data, href, integrity, lang, name,
  referrerpolicy, rel,
}
import docs/components/header.{HeaderProps, MenuItem, header}
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
              link([
                rel("stylesheet"),
                href(
                  "https://cdnjs.cloudflare.com/ajax/libs/flowbite/1.7.0/flowbite.min.css",
                ),
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
                [class("relative flex-1 flex flex-row")],
                [
                  component(sidebar, SidebarProps(pages, route)),
                  div(
                    [class("sm:ml-64")],
                    [
                      button(
                        [
                          data("drawer-target", "default-sidebar"),
                          data("drawer-toggle", "default-sidebar"),
                          class(
                            "inline-flex sm:hidden items-center p-2 mt-2 ml-3 text-sm text-gray-500 rounded-lg hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-200 dark:text-gray-400 dark:hover:bg-gray-700 dark:focus:ring-gray-600",
                          ),
                        ],
                        [i([class("fa-solid fa-bars")], [])],
                      ),
                      ..case route {
                        Introduction -> [
                          component(introduction_page, IntroductionPageProps),
                        ]
                        Components -> [
                          component(components_page, ComponentsPageProps),
                        ]
                        Misc -> [component(misc_page, MiscPageProps)]
                        Unknown -> [
                          component(not_found_page, NotFoundPageProps),
                        ]
                      }
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
