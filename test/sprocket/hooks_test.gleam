import gleam/int
import gleam/string
import gleam/option.{None}
import gleeunit/should
import gleam/erlang/process.{type Subject}
import sprocket/context.{type Context, OnMount, OnUpdate, WithDeps}
import sprocket/component.{component}
import sprocket/html/elements.{button, fragment, text}
import sprocket/html/attributes.{id, on_click}
import sprocket/hooks.{effect, handler, reducer}
import sprocket/test_helpers.{ClickEvent, live, render_event, render_html}
import utils/tally_counter

type Model {
  Model(count: Int)
}

type Msg {
  UpdateCount(Int)
  ResetCount
}

fn update(_model: Model, msg: Msg) -> Model {
  case msg {
    UpdateCount(count) -> {
      Model(count: count)
    }
    ResetCount -> {
      Model(count: 0)
    }
  }
}

fn initial() -> Model {
  Model(0)
}

type TestCounterProps {
  TestCounterProps
}

fn inc_initial_render_counter(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, Model(count: count), dispatch <- reducer(ctx, initial(), update)

  // Example effect with an empty list of dependencies, runs once on mount
  use ctx <- effect(
    ctx,
    fn() {
      dispatch(UpdateCount(count + 1))
      None
    },
    OnMount,
  )

  let current_count = int.to_string(count)

  component.render(
    ctx,
    fragment([text("current count is: "), text(current_count)]),
  )
}

pub fn effect_should_only_run_on_initial_render_test() {
  let view = component(inc_initial_render_counter, TestCounterProps)
  let spkt = live(view)

  let #(spkt, rendered) = render_html(spkt)

  rendered
  |> should.equal("current count is: 0")

  let #(spkt, rendered) = render_html(spkt)

  rendered
  |> should.equal("current count is: 1")

  let #(_spkt, rendered) = render_html(spkt)

  rendered
  |> should.equal("current count is: 1")
}

type IncEveryUpdateCounterProps {
  IncEveryUpdateCounterProps(tally: Subject(tally_counter.Message))
}

fn inc_on_every_update_counter(ctx: Context, props: IncEveryUpdateCounterProps) {
  // Example effect that runs on every update
  use ctx <- effect(
    ctx,
    fn() {
      tally_counter.increment(props.tally)
      None
    },
    OnUpdate,
  )

  component.render(ctx, text(""))
}

pub fn effect_should_run_on_every_update_test() {
  let assert Ok(tally) = tally_counter.start()

  let view =
    component(inc_on_every_update_counter, IncEveryUpdateCounterProps(tally))

  let spkt = live(view)

  let #(spkt, _rendered) = render_html(spkt)

  tally_counter.get_count(tally)
  |> should.equal(1)

  let #(spkt, _rendered) = render_html(spkt)

  tally_counter.get_count(tally)
  |> should.equal(2)

  let #(spkt, _rendered) = render_html(spkt)

  tally_counter.get_count(tally)
  |> should.equal(3)

  let #(_spkt, _rendered) = render_html(spkt)

  tally_counter.get_count(tally)
  |> should.equal(4)
}

fn inc_reset_on_button_click_counter(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, Model(count: count), dispatch <- reducer(ctx, initial(), update)

  // Example effect with an empty list of dependencies, runs once on mount
  use ctx <- effect(
    ctx,
    fn() {
      dispatch(UpdateCount(count + 1))
      None
    },
    WithDeps([]),
  )

  // Define event handlers
  use ctx, on_increment <- handler(
    ctx,
    fn(_) { dispatch(UpdateCount(count + 1)) },
  )
  use ctx, on_reset <- handler(ctx, fn(_) { dispatch(ResetCount) })

  let current_count = int.to_string(count)

  component.render(
    ctx,
    fragment([
      text("current count is: "),
      text(current_count),
      button([id("increment"), on_click(on_increment)], [text("increment")]),
      button([id("reset"), on_click(on_reset)], [text("reset")]),
    ]),
  )
}

pub fn effect_should_run_with_empty_deps_and_handle_events_test() {
  let view = component(inc_reset_on_button_click_counter, TestCounterProps)

  let spkt = live(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 1")

  // verify WithDeps([]) is only run a single time on mount
  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 1")

  // click increment button
  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 2")

  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 3")

  // click reset button
  let spkt = render_event(spkt, ClickEvent, "reset")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")
}
