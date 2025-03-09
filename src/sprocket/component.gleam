import gleam/dynamic
import sprocket/context.{type Element, Component, Provider}
import sprocket/internal/utils/unsafe_coerce.{unsafe_coerce}

/// Context used by stateful components.
pub type Context =
  context.Context

/// A StatefulComponent is a component that has an associated state, lifecycle and takes props as
/// input.
pub type StatefulComponent(p) =
  context.StatefulComponent(p)

/// Creates a new stateful component element from a given component function and props.
pub fn component(c: StatefulComponent(p), props: p) -> Element {
  let component =
    c
    |> dynamic.from()
    |> unsafe_coerce()

  let props =
    props
    |> dynamic.from()

  Component(component, props)
}

/// Creates a new provider element with the given key and value.
pub fn provider(key: String, value: a, element: Element) -> Element {
  Provider(key, dynamic.from(value), element)
}

/// Renders an element with the given context.
pub fn render(ctx, element) -> #(Context, Element) {
  #(ctx, element)
}
