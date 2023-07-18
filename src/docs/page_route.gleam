import docs/utils/logger

pub type Page {
  Page(title: String, route: PageRoute)
}

pub type PageRoute {
  Introduction
  Components
  StateManagement
  Hooks
  Events
  Misc
  Unknown
}

pub fn from_string(route: String) -> PageRoute {
  case route {
    "/" -> Introduction
    "/components" -> Components
    "/state" -> StateManagement
    "/hooks" -> Hooks
    "/events" -> Events
    "/misc" -> Misc
    _ -> Unknown
  }
}

pub fn href(route: PageRoute) -> String {
  case route {
    Introduction -> "/"
    Components -> "/components"
    StateManagement -> "/state"
    Hooks -> "/hooks"
    Events -> "/events"
    Misc -> "/misc"
    Unknown -> {
      logger.error("Unknown page route")
      panic
    }
  }
}
