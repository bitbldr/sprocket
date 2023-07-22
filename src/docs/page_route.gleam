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
  UnderTheHood
  Misc
  Unknown
}

pub fn from_string(route: String) -> PageRoute {
  case route {
    "/" -> Introduction
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
