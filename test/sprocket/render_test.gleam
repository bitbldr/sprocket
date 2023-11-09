import gleam/dynamic
import gleam/option.{None, Some}
import gleeunit/should
import sprocket/context.{Context, WithDeps}
import sprocket/component.{component, render}
import sprocket/html/elements.{a, text}
import sprocket/html/attributes.{classes}
import sprocket/hooks.{callback}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedEventHandler,
  RenderedText,
}
import sprocket/internal/render/identity

type TestProps {
  TestProps(title: String, href: String, is_active: Bool)
}

fn test_component(ctx: Context, props: TestProps) {
  let TestProps(title: title, href: _href, is_active: is_active) = props

  use ctx, on_click <- callback(ctx, fn(_) { todo }, WithDeps([]))

  render(
    ctx,
    [
      a(
        [
          classes([
            Some("block p-2 text-blue-500 hover:text-blue-700"),
            case is_active {
              True -> Some("font-bold")
              False -> None
            },
          ]),
          attributes.href("#"),
          attributes.on_click(on_click),
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
