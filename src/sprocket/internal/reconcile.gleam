import gleam/option.{type Option}
import gleam/dynamic.{type Dynamic}
import sprocket/context.{
  type AbstractFunctionalComponent, type ComponentHooks, type Context, Context,
}

pub type RenderedAttribute {
  RenderedAttribute(name: String, value: String)
  RenderedEventHandler(kind: String, id: String)
  RenderedClientHook(name: String, id: String)
}

pub type IgnoreRule {
  IgnoreAll
}

pub type RenderedElement {
  RenderedElement(
    tag: String,
    key: Option(String),
    attrs: List(RenderedAttribute),
    children: List(RenderedElement),
  )
  RenderedComponent(
    fc: AbstractFunctionalComponent,
    key: Option(String),
    props: Dynamic,
    hooks: ComponentHooks,
    el: RenderedElement,
  )
  RenderedFragment(key: Option(String), children: List(RenderedElement))
  RenderedIgnoreUpdate(rule: IgnoreRule, el: RenderedElement)
  RenderedText(text: String)
}

pub type ReconciledResult(a) {
  ReconciledResult(ctx: Context, reconciled: a)
}
