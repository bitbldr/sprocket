import gleam/option.{Option}
import gleam/dynamic.{Dynamic}
import sprocket/html/attributes.{Attribute}
import sprocket/context.{Context}

pub type AbstractFunctionalComponent =
  fn(Context, Dynamic) -> #(Context, List(Element))

pub type FunctionalComponent(p) =
  fn(Context, p) -> #(Context, List(Element))

pub type Element {
  Element(tag: String, attrs: List(Attribute), children: List(Element))
  Component(component: FunctionalComponent(Dynamic), props: Dynamic)
  Debug(id: String, meta: Option(Dynamic), element: Element)
  Keyed(key: String, element: Element)
  IgnoreUpdate(element: Element)
  SafeHtml(html: String)
  Raw(text: String)
}
