import docs/utils/logger

pub type Page {
  Page(title: String, route: PageRoute)
}

pub type PageRoute {
  Introduction
  Components
  Events
  StateManagement
  Effects
  Hooks
  Misc
  Unknown
}

pub fn from_string(route: String) -> PageRoute {
  case route {
    "/" -> Introduction
    "/components" -> Components
    "/events" -> Events
    "/state" -> StateManagement
    "/effects" -> Effects
    "/hooks" -> Hooks
    "/misc" -> Misc
    _ -> Unknown
  }
}

pub fn href(route: PageRoute) -> String {
  case route {
    Introduction -> "/"
    Components -> "/components"
    Events -> "/events"
    StateManagement -> "/state"
    Effects -> "/effects"
    Hooks -> "/hooks"
    Misc -> "/misc"
    Unknown -> {
      logger.error("Unknown page route")
      panic
    }
  }
}
