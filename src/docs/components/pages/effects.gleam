import sprocket/socket.{Socket}
import sprocket/component.{render}
import sprocket/html.{article, h1, p, text}

pub type EffectsPageProps {
  EffectsPageProps
}

pub fn effects_page(socket: Socket, _props: EffectsPageProps) {
  render(socket, [article([], [h1([], [text("Effects")]), p([], [text("")])])])
}
