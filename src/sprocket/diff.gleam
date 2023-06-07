import sprocket/render.{RenderedAttribute, RenderedComponent, RenderedElement}

pub fn reconcile(
  previous: RenderedElement,
  next: RenderedElement,
) -> RenderedElement {
  case previous, next {
    RenderedElement(prev_tag, ..), RenderedElement(next_tag, ..) if prev_tag != next_tag ->
      next

    RenderedElement(_prev_tag, prev_attrs, prev_children), RenderedElement(
      next_tag,
      next_attrs,
      next_children,
    ) ->
      RenderedElement(
        tag: next_tag,
        attrs: reconcile_attributes(prev_attrs, next_attrs),
        children: reconcile_children(prev_children, next_children),
      )

    RenderedComponent(_, _prev_props, prev_rendered), RenderedComponent(
      fc,
      next_props,
      next_rendered,
    ) ->
      RenderedComponent(
        fc: fc,
        props: next_props,
        rendered: reconcile_children(prev_rendered, next_rendered),
      )

    _, next_element -> next_element
  }
}

fn reconcile_attributes(
  previous: List(RenderedAttribute),
  next: List(RenderedAttribute),
) -> List(RenderedAttribute) {
  case previous, next {
    [], [] -> []
    [], next -> next
    previous, [] -> previous
    [prev_attr, ..prev_rest], [next_attr, ..next_rest] -> [
      reconcile_attribute(prev_attr, next_attr),
      ..reconcile_attributes(prev_rest, next_rest)
    ]
  }
}

fn reconcile_attribute(
  previous: RenderedAttribute,
  next: RenderedAttribute,
) -> RenderedAttribute {
  case previous, next {
    RenderedAttribute(prev_name, _), RenderedAttribute(next_name, next_value) if prev_name == next_name ->
      RenderedAttribute(prev_name, next_value)

    _, next_attr -> next_attr
  }
}

fn reconcile_children(
  previous: List(RenderedElement),
  next: List(RenderedElement),
) -> List(RenderedElement) {
  case previous, next {
    [], [] -> []
    [], next -> next
    previous, [] -> previous
    [prev_child, ..prev_rest], [next_child, ..next_rest] -> [
      reconcile(prev_child, next_child),
      ..reconcile_children(prev_rest, next_rest)
    ]
  }
}
