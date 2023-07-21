import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/html.{div, h1, text}
import sprocket/html/attributes.{class}

pub type NotFoundPageProps {
  NotFoundPageProps
}

pub fn not_found_page(ctx: Context, _props: NotFoundPageProps) {
  render(
    ctx,
    [
      div(
        [class("flex flex-col p-10")],
        [div([], [h1([class("text-xl mb-2")], [text("Page Not Found")])])],
      ),
    ],
  )
}
