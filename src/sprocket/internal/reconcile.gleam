import gleam/option.{type Option}
import gleam/dynamic.{type Dynamic}
import sprocket/context.{
  type AbstractFunctionalComponent, type ComponentHooks, type Context,
  type Element, type IgnoreScope, Context,
}

pub type ReconciledAttribute {
  ReconciledAttribute(name: String, value: String)
  ReconciledEventHandler(kind: String, id: String)
  ReconciledClientHook(name: String, id: String)
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
  ReconciledIgnoreUpdate(scope: IgnoreScope, el: ReconciledElement)
  ReconciledText(text: String)
}

pub type ReconciledResult {
  ReconciledResult(ctx: Context, reconciled: ReconciledElement)
}

pub type Reconciler {
  Reconciler(
    reconcile: fn(Context, Element, Option(ReconciledElement)) ->
      ReconciledResult,
  )
}

pub fn reconciler(reconciler: Reconciler, cb: fn(Reconciler) -> a) -> a {
  cb(reconciler)
}
