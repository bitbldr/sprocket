import gleeunit/should
import gleam/io
import gleam/string
import gleam/json
import gleam/dynamic
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedText,
}
import sprocket/diff.{reconcile}
import sprocket/render/json as json_renderer

// gleeunit test functions end in `_test`
pub fn diff_test() {
  let first =
    RenderedComponent(
      fc: fn(socket, _) { #(socket, []) },
      props: dynamic.from([]),
      rendered: [
        RenderedElement(
          tag: "div",
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fn(socket, _) { #(socket, []) },
      props: dynamic.from([]),
      rendered: [
        RenderedElement(
          tag: "div",
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              attrs: [],
              children: [RenderedText("Changed")],
            ),
          ],
        ),
      ],
    )

  let result = reconcile(first, second)

  rendered_element_to_json(result)
  |> should.equal(
    "
      {
        \"0\": {
          \"1\": {
            \"0\": \"Changed\"
          }
        }
      }
    "
    |> string.replace("\n", "")
    |> string.replace(" ", ""),
  )
}

fn rendered_element_to_json(rendered: RenderedElement) -> String {
  json_renderer.renderer().render(rendered)
  |> json.to_string()
}
