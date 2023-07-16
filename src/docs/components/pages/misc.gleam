import sprocket/socket.{Socket}
import sprocket/component.{render}
import sprocket/html.{article, div, h1, text}
import sprocket/html/attribute.{class}

pub type MiscPageProps {
  MiscPageProps
}

pub fn misc_page(socket: Socket, _props: MiscPageProps) {
  render(
    socket,
    [
      div(
        [class("flex flex-col p-10")],
        [
          article(
            [class("prose")],
            [h1([class("text-xl mb-2")], [text("Miscellaneous")])],
          ),
        ],
      ),
    ],
  )
}
