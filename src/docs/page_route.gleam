import docs/utils/logger

pub type PageRoute {
  Introduction
  Components
  Misc
  Unknown
}

pub fn from_string(route: String) -> PageRoute {
  case route {
    "/" -> Introduction
    "/components" -> Components
    "/misc" -> Misc
    _ -> Unknown
  }
}

pub fn href(route: PageRoute) -> String {
  case route {
    Introduction -> "/"
    Components -> "/components"
    Misc -> "/misc"
    Unknown -> {
      logger.error("Unknown page route")
      panic
    }
  }
}
