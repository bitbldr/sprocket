import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/html.{article, h1, p, text}

pub type UnderTheHoodProps {
  UnderTheHoodProps
}

pub fn under_the_hood_page(ctx: Context, _props: UnderTheHoodProps) {
  render(
    ctx,
    [
      article(
        [],
        [h1([], [text("Under the Hood")]), p([], [text("COMING SOON")])],
      ),
    ],
  )
}
