import gleam/string
import docs/utils/logger

pub type Page {
  Page(title: String, route: PageRoute)
}

pub type PageRoute {
  Introduction
  GettingStarted
  Components
  Events
  StateManagement
  Effects
  Hooks
  UnderTheHood
  Misc
  Unknown
}

pub fn from_string(route: String) -> PageRoute {
  let route = case string.ends_with(route, "/live") {
    True -> string.slice(route, 0, string.length(route) - 5)
    False -> route
  }

  let route = case route {
    "" -> "/"
    _ -> route
  }

  case route {
    "/" -> Introduction
    "/getting_started" -> GettingStarted
    "/components" -> Components
    "/props_and_events" -> Events
    "/state" -> StateManagement
    "/effects" -> Effects
    "/hooks" -> Hooks
    "/under_the_hood" -> UnderTheHood
    "/misc" -> Misc
    _ -> Unknown
  }
}

pub fn href(route: PageRoute) -> String {
  case route {
    Introduction -> "/"
    GettingStarted -> "/getting_started"
    Components -> "/components"
    Events -> "/props_and_events"
    StateManagement -> "/state"
    Effects -> "/effects"
    Hooks -> "/hooks"
    UnderTheHood -> "/under_the_hood"
    Misc -> "/misc"
    Unknown -> {
      logger.error("Unknown page route")
      panic
    }
  }
}
