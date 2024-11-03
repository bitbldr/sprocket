import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/option.{None}
import gleam/string
import gleeunit/should
import sprocket/component.{component}
import sprocket/context.{type Context, dep}
import sprocket/hooks.{type Cmd, effect, handler, reducer}
import sprocket/html/attributes.{id}
import sprocket/html/elements.{button, fragment, text}
import sprocket/html/events.{on_click}
import sprocket/test_helpers.{ClickEvent, connect, render_event, render_html}
import sprocket/test_helpers/tally_counter

type Model {
  Model(count: Int)
}

type Msg {
  SetCount(Int)
  ResetCount
  GenerateRandom
  CountDown(Int)
}

fn mock_random() -> Int {
  42
}

fn generate_random() -> Cmd(Msg) {
  fn(dispatch) {
    let random_number = mock_random()
    dispatch(SetCount(random_number))
  }
}

fn count_down_from(value) -> Cmd(Msg) {
  fn(dispatch) {
    case value > 0 {
      True -> dispatch(CountDown(value - 1))
      False -> Nil
    }
  }
}

fn update(model: Model, msg: Msg) -> #(Model, List(Cmd(Msg))) {
  case msg {
    SetCount(count) -> {
      #(Model(count: count), [])
    }
    ResetCount -> {
      #(Model(count: 0), [])
    }
    GenerateRandom -> {
      #(model, [generate_random()])
    }
    CountDown(value) -> {
      #(Model(count: value), [count_down_from(value)])
    }
  }
}

fn initial() -> #(Model, List(Cmd(Msg))) {
  #(Model(0), [])
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
      dispatch(SetCount(count + 1))
      None
    },
    [],
  )

  let current_count = int.to_string(count)

  component.render(
    ctx,
    fragment([text("current count is: "), text(current_count)]),
  )
}

pub fn effect_should_only_run_on_initial_render_test() {
  let view = component(inc_initial_render_counter, TestCounterProps)
  let spkt = connect(view)

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

type IncEverySetCounterProps {
  IncEverySetCounterProps(tally: Subject(tally_counter.Message))
}

fn inc_on_every_update_counter(ctx: Context, props: IncEverySetCounterProps) {
  // Example effect that runs on every update
  use ctx <- effect(
    ctx,
    fn() {
      tally_counter.increment(props.tally)
      None
    },
    [dep(ctx)],
  )

  component.render(ctx, text(""))
}

pub fn effect_should_run_on_every_update_test() {
  let assert Ok(tally) = tally_counter.start()

  let view =
    component(inc_on_every_update_counter, IncEverySetCounterProps(tally))

  let spkt = connect(view)

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
      dispatch(SetCount(count + 1))
      None
    },
    [],
  )

  // Define event handlers
  use ctx, increment <- handler(ctx, fn(_) { dispatch(SetCount(count + 1)) })
  use ctx, generate_random <- handler(ctx, fn(_) { dispatch(GenerateRandom) })
  use ctx, reset <- handler(ctx, fn(_) { dispatch(ResetCount) })

  let current_count = int.to_string(count)

  component.render(
    ctx,
    fragment([
      text("current count is: "),
      text(current_count),
      button([id("increment"), on_click(increment)], [text("increment")]),
      button([id("random"), on_click(generate_random)], [text("random")]),
      button([id("reset"), on_click(reset)], [text("reset")]),
    ]),
  )
}

pub fn effect_should_run_with_empty_deps_and_handle_events_test() {
  let view = component(inc_reset_on_button_click_counter, TestCounterProps)

  let spkt = connect(view)

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

fn inc_random_reset_counter(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, Model(count: count), dispatch <- reducer(ctx, initial(), update)

  // Define event handlers
  use ctx, increment <- handler(ctx, fn(_) { dispatch(SetCount(count + 1)) })
  use ctx, generate_random <- handler(ctx, fn(_) { dispatch(GenerateRandom) })
  use ctx, reset <- handler(ctx, fn(_) { dispatch(ResetCount) })

  let current_count = int.to_string(count)

  component.render(
    ctx,
    fragment([
      text("current count is: "),
      text(current_count),
      button([id("increment"), on_click(increment)], [text("increment")]),
      button([id("random"), on_click(generate_random)], [text("random")]),
      button([id("reset"), on_click(reset)], [text("reset")]),
    ]),
  )
}

pub fn reducer_should_run_cmds_test() {
  let view = component(inc_random_reset_counter, TestCounterProps)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")

  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 1")

  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 2")

  let spkt = render_event(spkt, ClickEvent, "reset")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")

  let spkt = render_event(spkt, ClickEvent, "random")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 42")
}

fn count_down(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, Model(count: count), dispatch <- reducer(
    ctx,
    #(Model(42), []),
    update,
  )

  // Define event handlers
  use ctx, start <- handler(ctx, fn(_) { dispatch(CountDown(count)) })

  let current_count = int.to_string(count)

  component.render(
    ctx,
    fragment([
      text("current count is: "),
      text(current_count),
      button([id("start"), on_click(start)], [text("start")]),
    ]),
  )
}

pub fn reducer_should_run_cmds_recursively_test() {
  let view = component(count_down, TestCounterProps)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 42")

  let spkt = render_event(spkt, ClickEvent, "start")

  process.sleep(100)

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")
}

fn component_with_initial_cmds(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, Model(count: count), dispatch <- reducer(
    ctx,
    #(Model(0), [generate_random()]),
    update,
  )

  // Define event handlers
  use ctx, reset <- handler(ctx, fn(_) { dispatch(ResetCount) })

  let current_count = int.to_string(count)

  component.render(
    ctx,
    fragment([
      text("current count is: "),
      text(current_count),
      button([id("reset"), on_click(reset)], [text("reset")]),
    ]),
  )
}

pub fn reducer_should_initialize_with_cmds_test() {
  let view = component(component_with_initial_cmds, TestCounterProps)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 42")

  let spkt = render_event(spkt, ClickEvent, "reset")

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")
}
