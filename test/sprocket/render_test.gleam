import gleam/dynamic
import gleam/option.{None}
import gleeunit/should
import sprocket/socket.{Socket}
import sprocket/component.{component, render}
import sprocket/html.{a, text}
import sprocket/html/attribute.{attribute, classes}
import sprocket/hooks.{WithDeps}
import sprocket/hooks/callback.{callback}
import sprocket/identifiable_callback.{CallbackFn}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedText,
}
import sprocket/render/identity

type TestProps {
  TestProps(title: String, href: String, is_active: Bool)
}

fn test_component(socket: Socket, props: TestProps) {
  let TestProps(title: title, href: _href, is_active: is_active) = props

  use socket, on_click <- callback(
    socket,
    CallbackFn(fn() { todo }),
    WithDeps([]),
  )

  render(
    socket,
    [
      a(
        [
          classes([
            "block p-2 text-blue-500 hover:text-blue-700",
            case is_active {
              True -> "font-bold"
              False -> ""
            },
          ]),
          attribute.href("#"),
          attribute.on_click(on_click),
        ],
        [text(title)],
      ),
    ],
  )
}

// gleeunit test functions end in `_test`
pub fn basic_render_test() {
  let rendered =
    render.render(
      component(
        test_component,
        TestProps(title: "Home", href: "/", is_active: True),
      ),
      identity.renderer(),
    )

  let assert RenderedComponent(
    _fc,
    _key,
    props,
    _hooks,
    [
      RenderedElement(
        tag: "a",
        key: None,
        attrs: [
          RenderedAttribute(
            "class",
            "block p-2 text-blue-500 hover:text-blue-700 font-bold",
          ),
          RenderedAttribute("href", "#"),
          RenderedEventHandler("click", _),
        ],
        children: [RenderedText("Home")],
      ),
    ],
  ) = rendered

  props
  |> should.equal(dynamic.from(TestProps(
    title: "Home",
    href: "/",
    is_active: True,
  )))
}
