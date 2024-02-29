import gleam/dynamic
import gleam/option.{None, Some}
import gleeunit/should
import ids/cuid
import sprocket/context.{type Context, type Element}
import sprocket/component.{component, render}
import sprocket/html/elements.{a, div, fragment, text}
import sprocket/html/attributes.{class, classes}
import sprocket/hooks.{handler, provider}
import sprocket/internal/reconcilers/recursive.{reconcile}
import sprocket/internal/reconcile.{
  type ReconciledElement, ReconciledAttribute, ReconciledComponent,
  ReconciledElement, ReconciledEventHandler, ReconciledFragment,
  ReconciledResult, ReconciledText,
}

// Renders the given element as a stateless element to html.
pub fn render_el(el: Element) -> ReconciledElement {
  // Internally this function uses the reconciler with an empty previous element
  // and a placeholder ctx but then discards the ctx and returns the result.
  let assert Ok(cuid_channel) = cuid.start()

  let ctx =
    context.new(el, cuid_channel, None, fn() { Nil }, fn(_index, _updater) {
      Nil
    })

  let ReconciledResult(reconciled: reconciled, ..) =
    reconcile(ctx, el, None, None)

  reconciled
}

type TestProps {
  TestProps(title: String, href: String, is_active: Bool)
}

fn test_component(ctx: Context, props: TestProps) {
  let TestProps(title: title, href: _href, is_active: is_active) = props

  use ctx, handle_click <- handler(ctx, fn(_) { Nil })

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
        attributes.on_click(handle_click),
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
      tag: "a",
      key: None,
      attrs: [
        ReconciledAttribute(
          "class",
          "block p-2 text-blue-500 hover:text-blue-700 font-bold",
        ),
        ReconciledAttribute("href", "#"),
        ReconciledEventHandler("click", _),
      ],
      children: [ReconciledText("Home")],
    ),
  ) = rendered

  props
  |> should.equal(
    dynamic.from(TestProps(title: "Home", href: "/", is_active: True)),
  )
}

fn test_component_with_fragment(ctx: Context, _props: TestProps) {
  use ctx, handle_click <- handler(ctx, fn(_) { Nil })
  use ctx, handle_click_2 <- handler(ctx, fn(_) { Nil })

  render(
    ctx,
    fragment([
      a(
        [
          class("block p-2 text-blue-500 hover:text-blue-700"),
          attributes.href("#one"),
          attributes.on_click(handle_click),
        ],
        [text("One")],
      ),
      a(
        [
          class("block p-2 text-blue-500 hover:text-blue-700"),
          attributes.href("#two"),
          attributes.on_click(handle_click_2),
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
          tag: "a",
          key: None,
          attrs: [
            ReconciledAttribute(
              "class",
              "block p-2 text-blue-500 hover:text-blue-700",
            ),
            ReconciledAttribute("href", "#one"),
            ReconciledEventHandler("click", _),
          ],
          children: [ReconciledText("One")],
        ),
        ReconciledElement(
          tag: "a",
          key: None,
          attrs: [
            ReconciledAttribute(
              "class",
              "block p-2 text-blue-500 hover:text-blue-700",
            ),
            ReconciledAttribute("href", "#two"),
            ReconciledEventHandler("click", _),
          ],
          children: [ReconciledText("Two")],
        ),
      ],
    ),
  ) = rendered

  props
  |> dynamic.unsafe_coerce
  |> should.equal(TestProps(title: "Home", href: "/", is_active: True))
}

type TitleContext {
  TitleContext(title: String)
}

fn test_component_with_context_title(ctx: Context, props: TestProps) {
  let TestProps(href: _href, is_active: is_active, ..) = props

  use ctx, title <- provider(ctx, "title")

  let title = case title {
    Some(TitleContext(title: title)) -> title
    None -> "No title"
  }

  use ctx, handle_click <- handler(ctx, fn(_) { Nil })

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
        attributes.on_click(handle_click),
      ],
      [text(title)],
    ),
  )
}

pub fn renders_component_with_context_provider_test() {
  let rendered =
    render_el(
      div([class("first div")], [
        context.provider(
          "title",
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
    tag: "div",
    key: None,
    attrs: [ReconciledAttribute("class", "first div")],
    children: [
      ReconciledElement(
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
              tag: "a",
              key: None,
              attrs: [
                ReconciledAttribute(
                  "class",
                  "block p-2 text-blue-500 hover:text-blue-700 font-bold",
                ),
                ReconciledAttribute("href", "#"),
                ReconciledEventHandler("click", _),
              ],
              children: [ReconciledText("A different title")],
            ),
          ),
        ],
      ),
    ],
  ) = rendered
}
