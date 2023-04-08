import gleam/list.{at}
import sprocket/html/attrs.{HtmlAttr}

type StateValue =
  String

pub type Element {
  Element(tag: String, attrs: List(HtmlAttr), children: List(Element))
  Component(c: fn(ComponentContext) -> List(Element))
  RawHtml(html: String)
}

// LiveRoot

pub fn raw(html: String) {
  RawHtml(html)
}

pub type Hook {
  State(state: StateValue, updater: fn(StateValue) -> StateValue)
}

pub type ComponentContext {
  ComponentContext(
    hooks: List(Hook),
    push_hook: fn(Hook) -> Hook,
    h_index: Int,
    state_updater: fn(Int) -> fn(StateValue) -> StateValue,
  )
}

pub fn use_state(ctx: ComponentContext, initial: StateValue) -> Hook {
  let ComponentContext(
    hooks: hooks,
    h_index: h_index,
    push_hook: push_hook,
    state_updater: state_updater,
  ) = ctx

  case at(hooks, h_index) {
    Ok(h) -> h
    Error(Nil) -> push_hook(State(initial, state_updater(h_index)))
  }
}
