import sprocket/socket.{Socket}
import sprocket/component.{render}
import sprocket/html.{article, h1, h2, p, text}

pub type EventsPageProps {
  EventsPageProps
}

pub fn events_page(socket: Socket, _props: EventsPageProps) {
  render(socket, [article([], [h1([], [text("Events")]), p([], [text("")])])])
}
