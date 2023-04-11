import gleam/list.{at}
import sprocket/html/attrs.{HtmlAttr}

pub type StateValue =
  Int

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
    fetch_hook: fn(Int) -> Result(Hook, Nil),
    pop_hook_index: fn() -> Int,
    state_updater: fn(Int) -> fn(StateValue) -> StateValue,
  )
}

pub fn use_state(ctx: ComponentContext, initial: StateValue) -> Hook {
  let ComponentContext(
    hooks: hooks,
    pop_hook_index: pop_hook_index,
    push_hook: push_hook,
    fetch_hook: fetch_hook,
    state_updater: state_updater,
  ) = ctx

  let h_index = pop_hook_index()

  case fetch_hook(h_index) {
    Ok(h) -> h
    Error(Nil) -> push_hook(State(initial, state_updater(h_index)))
  }
}
