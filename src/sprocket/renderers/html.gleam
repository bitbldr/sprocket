import gleam/dynamic.{type Dynamic, field}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/string_builder.{type StringBuilder}
import sprocket/internal/constants
import sprocket/internal/reconcile.{
  type ReconciledAttribute, type ReconciledElement, ReconciledAttribute,
  ReconciledComponent, ReconciledCustom, ReconciledElement, ReconciledFragment,
  ReconciledIgnoreUpdate, ReconciledText,
}
import sprocket/render.{type Renderer, Renderer}

pub fn html_renderer() -> Renderer(String) {
  Renderer(render: fn(el: ReconciledElement) {
    render(el)
    |> string_builder.to_string()
  })
}

fn render(el: ReconciledElement) -> StringBuilder {
  case el {
    ReconciledElement(tag: tag, key: key, attrs: attrs, children: children) ->
      element(tag, key, attrs, children)
    ReconciledComponent(el: el, ..) -> component(el)
    ReconciledFragment(children: children, ..) -> fragment(children)
    ReconciledIgnoreUpdate(el) -> render(el)
    ReconciledText(text: t) -> text(t)
    ReconciledCustom(kind: kind, data: data) -> custom(kind, data)
  }
}

fn el(
  tag: String,
  attrs: StringBuilder,
  inner_html: StringBuilder,
) -> StringBuilder {
  string_builder.concat([
    string_builder.from_string("<"),
    string_builder.from_string(tag),
    attrs,
    string_builder.from_string(">"),
    inner_html,
    string_builder.from_string("</"),
    string_builder.from_string(tag),
    string_builder.from_string(">"),
  ])
}

fn element(
  tag: String,
  key: Option(String),
  attrs: List(ReconciledAttribute),
  children: List(ReconciledElement),
) -> StringBuilder {
  let rendered_attrs =
    attrs
    |> list.fold(string_builder.new(), fn(acc, attr) {
      case attr {
        ReconciledAttribute(name, value) -> {
          string_builder.append_builder(
            acc,
            string_builder.from_strings([" ", name, "=\"", value, "\""]),
          )
        }
        _ -> acc
      }
    })

  let rendered_attrs = case key {
    Some(k) ->
      string_builder.append_builder(
        rendered_attrs,
        string_builder.from_strings([" ", constants.key_attr, "=\"", k, "\""]),
      )
    None -> rendered_attrs
  }

  let inner_html =
    children
    |> list.fold(string_builder.new(), fn(acc, child) {
      string_builder.append_builder(acc, render(child))
    })

  el(tag, rendered_attrs, inner_html)
}

fn component(el: ReconciledElement) {
  render(el)
}

fn fragment(children: List(ReconciledElement)) {
  children
  |> list.fold(string_builder.new(), fn(acc, child) {
    string_builder.append_builder(acc, render(child))
  })
}

fn safe_replace_char(key: String) -> String {
  case key {
    "&" -> "&amp;"
    "<" -> "&lt;"
    ">" -> "&gt;"
    "\"" -> "&quot;"
    "'" -> "&#39;"
    "/" -> "&#x2F;"
    "`" -> "&#x60;"
    "=" -> "&#x3D;"
    _ -> key
  }
}

fn escape_html(unsafe: String) {
  string.to_graphemes(unsafe)
  |> list.fold(string_builder.new(), fn(sb, grapheme) {
    string_builder.append(sb, safe_replace_char(grapheme))
  })
  |> string_builder.to_string
}

fn text(t: String) -> StringBuilder {
  escape_html(t)
  |> string_builder.from_string()
}

fn custom(kind: String, data: String) -> StringBuilder {
  case kind {
    "raw" -> {
      case json.decode(data, decode_raw) {
        Ok(RawHtml(tag, raw_html)) ->
          el(
            tag,
            string_builder.from_string(""),
            string_builder.from_string(raw_html),
          )
        Error(_) -> string_builder.from_string("")
      }
    }
    _ -> string_builder.from_string("")
  }
}

type RawHtml {
  RawHtml(tag: String, raw_html: String)
}

fn decode_raw(data: Dynamic) {
  data
  |> dynamic.decode2(
    RawHtml,
    field("tag", dynamic.string),
    field("innerHtml", dynamic.string),
  )
}
