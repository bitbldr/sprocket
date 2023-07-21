import gleam/dynamic
import sprocket/element.{Component, Element, FunctionalComponent}
import sprocket/context.{Context}

pub fn component(c: FunctionalComponent(p), props: p) -> Element {
  // // This function wrapper will not work since we need to compare the original function
  // // when computing the diff and this will create a different function on every render
  // let component = fn(ctx: Context, props: Dynamic) -> #(Context, List(Element)) {
  //   let props = dynamic.unsafe_coerce(props)
  //   fc.component(ctx, props)
  // }

  // Instead, we will just use dynamic.unsafe_coerce to coerce the function to the correct type
  let component =
    c
    |> dynamic.from()
    |> dynamic.unsafe_coerce()

  let props =
    props
    |> dynamic.from()

  Component(component, props)
}

pub fn render(ctx, elements) -> #(Context, List(Element)) {
  #(ctx, elements)
}
