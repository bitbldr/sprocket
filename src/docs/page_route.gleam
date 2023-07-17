import docs/utils/logger

pub type PageRoute {
  Introduction
  Components
  Hooks
  StateManagement
  Misc
  Unknown
}

pub fn from_string(route: String) -> PageRoute {
  case route {
    "/" -> Introduction
    "/components" -> Components
    "/state" -> StateManagement
    "/hooks" -> Hooks
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
    Misc -> "/misc"
    Unknown -> {
      logger.error("Unknown page route")
      panic
    }
  }
}
