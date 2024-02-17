import gleam/option.{type Option}
import gleam/dynamic.{type Dynamic}
import sprocket/context.{
  type AbstractFunctionalComponent, type ComponentHooks, type Context, Context,
}

pub type ReconciledAttribute {
  ReconciledAttribute(name: String, value: String)
  ReconciledEventHandler(kind: String, id: String)
  ReconciledClientHook(name: String, id: String)
}

pub type IgnoreRule {
  IgnoreAll
}

pub type ReconciledElement {
  ReconciledElement(
    tag: String,
    key: Option(String),
    attrs: List(ReconciledAttribute),
    children: List(ReconciledElement),
  )
  ReconciledComponent(
    fc: AbstractFunctionalComponent,
    key: Option(String),
    props: Dynamic,
    hooks: ComponentHooks,
    el: ReconciledElement,
  )
  ReconciledFragment(key: Option(String), children: List(ReconciledElement))
  ReconciledIgnoreUpdate(rule: IgnoreRule, el: ReconciledElement)
  ReconciledText(text: String)
}

pub type ReconciledResult(a) {
  ReconciledResult(ctx: Context, reconciled: a)
}
