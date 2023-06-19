import gleeunit/should
import gleam/io
import gleam/string
import gleam/json
import gleam/dynamic
import gleam/option.{None, Some}
import sprocket/render.{
  RenderedAttribute, RenderedComponent, RenderedElement, RenderedText,
}
import sprocket/patch.{Change, Patch, Replace, Update}

// gleeunit test functions end in `_test`
pub fn patch_test() {
  let fc = fn(socket, _) { #(socket, []) }
  let props = dynamic.from([])

  let first =
    RenderedComponent(
      fc: fc,
      props: props,
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("World")],
            ),
          ],
        ),
      ],
    )

  let second =
    RenderedComponent(
      fc: fc,
      props: props,
      children: [
        RenderedElement(
          tag: "div",
          key: None,
          attrs: [],
          children: [
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Hello")],
            ),
            RenderedElement(
              tag: "p",
              key: None,
              attrs: [],
              children: [RenderedText("Changed")],
            ),
          ],
        ),
      ],
    )

  patch.create(first, second)
  |> should.equal(Update(
    attrs: None,
    children: Some([
      #(
        0,
        Update(
          attrs: None,
          children: Some([
            #(
              1,
              Update(
                attrs: None,
                children: Some([#(0, Change(text: "Changed"))]),
              ),
            ),
          ]),
        ),
      ),
    ]),
  ))
  //   let result = patch(first, second)

  //   rendered_element_to_json(result)
  //   |> should.equal(
  //     "
  //       {
  //         \"0\": {
  //           \"1\": {
  //             \"0\": \"Changed\"
  //           }
  //         }
  //       }
  //     "
  //     |> string.replace("\n", "")
  //     |> string.replace(" ", ""),
  //   )
  // }

  // fn rendered_element_to_json(patch: Diff) -> String {
  //   json_renderer.renderer().render(patch)
  //   |> json.to_string()
}
