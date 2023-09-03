import gleam/list
import gleam/result
import gleam/option.{None}
import sprocket/context.{Context}
import sprocket/component.{component, render}
import sprocket/html.{body, div, head, html, link, meta, script, title}
import sprocket/html/attributes.{
  charset, class, content, crossorigin, href, id, integrity, lang, media, name,
  referrerpolicy, rel, src,
}
import sprocket/internal/utils/ordered_map.{KeyedItem}
import docs/components/header.{HeaderProps, MenuItem, header}
import docs/components/responsive_drawer.{
  ResponsiveDrawerProps, responsive_drawer,
}
import docs/components/sidebar.{SidebarProps, sidebar}
import docs/components/prev_next_nav.{PrevNextNavProps, prev_next_nav}
import docs/components/pages/introduction.{
  IntroductionPageProps, introduction_page,
}
import docs/components/pages/components.{ComponentsPageProps, components_page}
import docs/components/pages/misc.{MiscPageProps, misc_page}
import docs/components/pages/not_found.{NotFoundPageProps, not_found_page}
import docs/components/pages/hooks.{HooksPageProps, hooks_page}
import docs/components/pages/props_and_events.{
  PropsAndEventsPageProps, props_and_events_page,
}
import docs/components/pages/effects.{EffectsPageProps, effects_page}
import docs/components/pages/state_management.{
  StateManagementPageProps, state_management_page,
}
import docs/components/pages/under_the_hood.{
  UnderTheHoodProps, under_the_hood_page,
}
import docs/page_route.{
  Components, Effects, Events, Hooks, Introduction, Misc, Page, PageRoute,
  StateManagement, UnderTheHood, Unknown,
}

pub type PageViewProps {
  PageViewProps(route: PageRoute, path_segments: List(String))
}

pub fn page_view(ctx: Context, props: PageViewProps) {
  let PageViewProps(route: route, ..) = props

  // TODO: use memoization hook to avoid re-computing this on every render
  let pages =
    [
      Page("Introduction", Introduction),
      Page("Components", Components),
      Page("Props and Events", Events),
      Page("State Management", StateManagement),
      Page("Effects", Effects),
      Page("Hooks", Hooks),
      Page("Under the Hood", UnderTheHood),
      Page("Misc.", Misc),
    ]
    |> list.map(fn(page) { KeyedItem(page.route, page) })
    |> ordered_map.from_list()

  let page_title =
    pages
    |> ordered_map.get(route)
    |> result.map(fn(page) { page.title <> " - Sprocket" })
    |> result.unwrap("Sprocket")

  render(
    ctx,
    [
      html(
        [lang("en")],
        [
          head(
            [],
            [
              title(page_title),
              meta([charset("utf-8")]),
              meta([
                name("viewport"),
                content("width=device-width, initial-scale=1"),
              ]),
              meta([
                name("description"),
                content(
                  "Sprocket is a library for building real-time server components in Gleam.",
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
                id("syntax-theme"),
                rel("stylesheet"),
                media("(prefers-color-scheme: dark)"),
                href(
                  "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.8.0/build/styles/atom-one-dark.min.css",
                ),
              ]),
              link([
                id("syntax-theme"),
                rel("stylesheet"),
                media(
                  "(prefers-color-scheme: light), (prefers-color-scheme: no-preference)",
                ),
                href(
                  "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@11.8.0/build/styles/atom-one-light.min.css",
                ),
              ]),
              script(
                [
                  src(
                    "//cdnjs.cloudflare.com/ajax/libs/highlight.js/11.0.1/highlight.min.js",
                  ),
                ],
                None,
              ),
              script(
                [src("https://gleam.run/javascript/highlightjs-gleam.js")],
                None,
              ),
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
                      MenuItem("Github", "https://github.com/bitbldr/sprocket"),
                    ]),
                  ),
                ],
              ),
              component(
                responsive_drawer,
                ResponsiveDrawerProps(
                  drawer: component(sidebar, SidebarProps(pages, route)),
                  content: div(
                    [
                      class(
                        "prose dark:prose-invert prose-sm md:prose-base container mx-auto p-12",
                      ),
                    ],
                    [
                      case route {
                        Introduction ->
                          component(introduction_page, IntroductionPageProps)
                        Components ->
                          component(components_page, ComponentsPageProps)
                        Events ->
                          component(
                            props_and_events_page,
                            PropsAndEventsPageProps,
                          )
                        StateManagement ->
                          component(
                            state_management_page,
                            StateManagementPageProps,
                          )
                        Effects -> component(effects_page, EffectsPageProps)
                        Hooks -> component(hooks_page, HooksPageProps)
                        UnderTheHood ->
                          component(under_the_hood_page, UnderTheHoodProps)
                        Misc -> component(misc_page, MiscPageProps)
                        Unknown -> component(not_found_page, NotFoundPageProps)
                      },
                      component(prev_next_nav, PrevNextNavProps(pages, route)),
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
