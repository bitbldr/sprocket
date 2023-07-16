import sprocket/internal/socket.{Socket}
import sprocket/component.{render}
import sprocket/html.{div, h1, text}
import sprocket/html/attribute.{class}

pub type ComponentsPageProps {
  ComponentsPageProps
}

pub fn components_page(socket: Socket, _props: ComponentsPageProps) {
  render(
    socket,
    [
      div(
        [class("flex flex-col p-10")],
        [div([], [h1([class("text-xl mb-2")], [text("Components")])])],
      ),
    ],
  )
}
