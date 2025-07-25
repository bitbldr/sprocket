import gleam/option.{None, Some}
import gleeunit/should
import sprocket.{component, render}
import sprocket/hooks.{provide}
import sprocket/html/attributes.{class, classes}
import sprocket/html/elements.{a, div, fragment, raw, text}
import sprocket/html/events
import sprocket/internal/context.{type Context, type Element, Attribute}
import sprocket/internal/reconcile.{
  type ReconciledElement, ReconciledAttribute, ReconciledComponent,
  ReconciledCustom, ReconciledElement, ReconciledEventHandler,
  ReconciledFragment, ReconciledResult, ReconciledText,
}
import sprocket/internal/reconcilers/recursive.{reconcile}
import sprocket/internal/utils/common.{dynamic_from}
import sprocket/internal/utils/cuid
import sprocket/internal/utils/unsafe_coerce.{unsafe_coerce}

// Renders the given element as a stateless element to html.
pub fn render_el(el: Element) -> ReconciledElement {
  // Internally this function uses the reconciler with an empty previous element
  // and a placeholder ctx but then discards the ctx and returns the result.
  let assert Ok(cuid_channel) = cuid.start()

  let render_update = fn() { Nil }
  let update_hook = fn(_index, _updater) { Nil }

  let ctx =
    context.new(
      el,
      cuid_channel,
      fn(_, _, _) { Nil },
      render_update,
      update_hook,
    )

  let ReconciledResult(reconciled: reconciled, ..) =
    reconcile(ctx, el, None, None)

  reconciled
}

type TestProps {
  TestProps(title: String, href: String, is_active: Bool)
}

fn test_component(ctx: Context, props: TestProps) {
  let TestProps(title: title, href: _href, is_active: is_active) = props

  let handle_click = fn(_) { Nil }

  render(
    ctx,
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
        events.on_click(handle_click),
      ],
      [text(title)],
    ),
  )
}

// gleeunit test functions end in `_test`
pub fn basic_render_test() {
  let rendered =
    render_el(component(
      test_component,
      TestProps(title: "Home", href: "/", is_active: True),
    ))

  let assert ReconciledComponent(
    _fc,
    _key,
    props,
    _hooks,
    ReconciledElement(
      id: _,
      tag: "a",
      key: None,
      attrs: [
        ReconciledAttribute(
          "class",
          "block p-2 text-blue-500 hover:text-blue-700 font-bold",
        ),
        ReconciledAttribute("href", "#"),
        ReconciledEventHandler(_, "click"),
      ],
      children: [ReconciledText("Home")],
    ),
  ) = rendered

  props
  |> should.equal(
    dynamic_from(TestProps(title: "Home", href: "/", is_active: True)),
  )
}

fn test_component_with_fragment(ctx: Context, _props: TestProps) {
  let handle_click = fn(_) { Nil }
  let handle_click_2 = fn(_) { Nil }

  render(
    ctx,
    fragment([
      a(
        [
          class("block p-2 text-blue-500 hover:text-blue-700"),
          attributes.href("#one"),
          events.on_click(handle_click),
        ],
        [text("One")],
      ),
      a(
        [
          class("block p-2 text-blue-500 hover:text-blue-700"),
          attributes.href("#two"),
          events.on_click(handle_click_2),
        ],
        [text("Two")],
      ),
    ]),
  )
}

pub fn render_with_fragment_test() {
  let rendered =
    render_el(component(
      test_component_with_fragment,
      TestProps(title: "Home", href: "/", is_active: True),
    ))

  let assert ReconciledComponent(
    _fc,
    _key,
    props,
    _hooks,
    ReconciledFragment(
      None,
      [
        ReconciledElement(
          id: _,
          tag: "a",
          key: None,
          attrs: [
            ReconciledAttribute(
              "class",
              "block p-2 text-blue-500 hover:text-blue-700",
            ),
            ReconciledAttribute("href", "#one"),
            ReconciledEventHandler(_, "click"),
          ],
          children: [ReconciledText("One")],
        ),
        ReconciledElement(
          id: _,
          tag: "a",
          key: None,
          attrs: [
            ReconciledAttribute(
              "class",
              "block p-2 text-blue-500 hover:text-blue-700",
            ),
            ReconciledAttribute("href", "#two"),
            ReconciledEventHandler(_, "click"),
          ],
          children: [ReconciledText("Two")],
        ),
      ],
    ),
  ) = rendered

  props
  |> unsafe_coerce
  |> should.equal(TestProps(title: "Home", href: "/", is_active: True))
}

type TitleContext {
  TitleContext(title: String)
}

const title_context_provider_key = "title"

fn title_context_provider(
  title_context: TitleContext,
  element: Element,
) -> Element {
  provide(title_context_provider_key, title_context, element)
}

fn test_component_with_context_title(ctx: Context, props: TestProps) {
  let TestProps(href: _href, is_active: is_active, ..) = props

  use ctx, title <- hooks.provider(ctx, title_context_provider_key)

  let title = case title {
    Some(TitleContext(title: title)) -> title
    None -> "No title"
  }

  let handle_click = fn(_) { Nil }

  render(
    ctx,
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
        events.on_click(handle_click),
      ],
      [text(title)],
    ),
  )
}

pub fn renders_component_with_context_provider_test() {
  let rendered =
    render_el(
      div([class("first div")], [
        title_context_provider(
          TitleContext(title: "A different title"),
          div([class("second div")], [
            component(
              test_component_with_context_title,
              TestProps(title: "Home", href: "/", is_active: True),
            ),
          ]),
        ),
      ]),
    )

  let assert ReconciledElement(
    id: _,
    tag: "div",
    key: None,
    attrs: [ReconciledAttribute("class", "first div")],
    children: [
      ReconciledElement(
        id: _,
        tag: "div",
        key: None,
        attrs: [ReconciledAttribute("class", "second div")],
        children: [
          ReconciledComponent(
            _fc,
            _key,
            _props,
            _hooks,
            ReconciledElement(
              id: _,
              tag: "a",
              key: None,
              attrs: [
                ReconciledAttribute(
                  "class",
                  "block p-2 text-blue-500 hover:text-blue-700 font-bold",
                ),
                ReconciledAttribute("href", "#"),
                ReconciledEventHandler(_, "click"),
              ],
              children: [ReconciledText("A different title")],
            ),
          ),
        ],
      ),
    ],
  ) = rendered
}

type EmptyProps {
  EmptyProps
}

fn test_component_with_custom_element(ctx: Context, _props) {
  render(
    ctx,
    raw(
      "div",
      [Attribute("some", dynamic_from("attribute"))],
      "An unescaped <b>raw <em>html</em></b> <span style=\"color: blue\">string</span></b>",
    ),
  )
}

pub fn renders_test_component_with_custom_element_test() {
  let rendered =
    render_el(component(test_component_with_custom_element, EmptyProps))

  let assert ReconciledComponent(
    _fc,
    _key,
    _props,
    _hooks,
    ReconciledCustom(
      kind: "raw",
      data: "{\"tag\":\"div\",\"attrs\":{\"some\":\"attribute\"},\"innerHtml\":\"An unescaped <b>raw <em>html</em></b> <span style=\\\"color: blue\\\">string</span></b>\"}",
    ),
  ) = rendered
}
