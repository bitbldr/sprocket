import gleam/dynamic
import sprocket/internal/element.{Component, Element, FunctionalComponent}
import sprocket/internal/socket.{Socket}

pub fn component(c: FunctionalComponent(p), props: p) -> Element {
  // // This function wrapper will not work since we need to compare the original function
  // // when computing the diff and this will create a different function on every render
  // let component = fn(socket: Socket, props: Dynamic) -> #(Socket, List(Element)) {
  //   let props = dynamic.unsafe_coerce(props)
  //   fc.component(socket, props)
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

pub fn render(socket, elements) -> #(Socket, List(Element)) {
  #(socket, elements)
}
