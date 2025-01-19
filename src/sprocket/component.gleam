import gleam/dynamic
import sprocket/context.{
  type Context, type Element, type StatefulComponent, Component,
}
import sprocket/internal/utils/unsafe_coerce.{unsafe_coerce}

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

pub fn render(ctx, elements) -> #(Context, Element) {
  #(ctx, elements)
}
