import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import sprocket/context.{
  type AbstractFunctionalComponent, type ComponentHooks, type Context,
  type Element, Context,
}
import sprocket/internal/utils/unique.{type Unique}

pub type ReconciledAttribute {
  ReconciledAttribute(name: String, value: String)
  ReconciledEventHandler(kind: String, id: String)
  ReconciledClientHook(name: String, id: String)
}

pub type ReconciledElementId

pub type ReconciledElement {
  ReconciledElement(
    id: Unique(ReconciledElementId),
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
  ReconciledIgnoreUpdate(el: ReconciledElement)
  ReconciledText(text: String)
  ReconciledCustom(kind: String, data: String)
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
