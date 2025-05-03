import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/option.{None}
import gleam/string
import gleeunit/should
import sprocket.{type Context, component, render}
import sprocket/hooks.{type Dispatcher, dep, effect, reducer, state}
import sprocket/html/attributes.{id}
import sprocket/html/elements.{button, fragment, text}
import sprocket/html/events.{on_click}
import sprocket/test_helpers.{
  ClickEvent, connect, render_event, render_html, wait_until,
}
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

fn generate_random(dispatch) {
  process.start(
    fn() {
      let random_number = mock_random()
      dispatch(SetCount(random_number))
    },
    False,
  )
}

fn count_down_from(dispatch, value) {
  process.start(
    fn() {
      case value > 0 {
        True -> dispatch(CountDown(value - 1))
        False -> Nil
      }
    },
    False,
  )
}

fn update(model: Model, msg: Msg, dispatch: Dispatcher(Msg)) -> Model {
  case msg {
    SetCount(count) -> {
      Model(count: count)
    }
    ResetCount -> {
      Model(count: 0)
    }
    GenerateRandom -> {
      generate_random(dispatch)

      model
    }
    CountDown(value) -> {
      count_down_from(dispatch, value)

      Model(count: value)
    }
  }
}

fn init(_dispatch: Dispatcher(Msg)) -> Model {
  Model(0)
}

fn inc_initial_render_counter(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, count, set_count <- state(ctx, 0)

  // Example effect with an empty list of dependencies, runs once on mount
  use ctx <- effect(
    ctx,
    fn() {
      set_count(count + 1)
      None
    },
    [],
  )

  let current_count = int.to_string(count)

  render(ctx, fragment([text("current count is: "), text(current_count)]))
}

pub fn effect_should_only_run_on_initial_render_test() {
  let view = component(inc_initial_render_counter, Nil)
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

  render(ctx, text(""))
}

pub fn effect_should_run_on_every_update_test() {
  let assert Ok(tally) = tally_counter.start()

  let view =
    component(inc_on_every_update_counter, IncEverySetCounterProps(tally))

  let spkt = connect(view)

  wait_until(fn() { tally_counter.get_count(tally) == 1 }, 1000)

  let #(spkt, _rendered) = render_html(spkt)

  tally_counter.get_count(tally)
  |> should.equal(2)

  let #(spkt, _rendered) = render_html(spkt)

  tally_counter.get_count(tally)
  |> should.equal(3)

  let #(_spkt, _rendered) = render_html(spkt)

  tally_counter.get_count(tally)
  |> should.equal(4)

  let #(_spkt, _rendered) = render_html(spkt)

  tally_counter.get_count(tally)
  |> should.equal(5)
}

fn inc_reset_on_button_click_counter(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, count, set_count <- state(ctx, 0)

  // Example effect with an empty list of dependencies, runs once on mount
  use ctx <- effect(
    ctx,
    fn() {
      set_count(count + 1)
      None
    },
    [],
  )

  // Define event handlers
  let increment = fn(_) { set_count(count + 1) }
  let reset = fn(_) { set_count(0) }

  let current_count = int.to_string(count)

  render(
    ctx,
    fragment([
      text("current count is: "),
      text(current_count),
      button([id("increment"), on_click(increment)], [text("increment")]),
      button([id("reset"), on_click(reset)], [text("reset")]),
    ]),
  )
}

pub fn effect_should_run_with_empty_deps_and_handle_events_test() {
  let view = component(inc_reset_on_button_click_counter, Nil)

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
  use ctx, Model(count: count), dispatch <- reducer(ctx, init, update)

  // Define event handlers
  let increment = fn(_) { dispatch(SetCount(count + 1)) }
  let generate_random = fn(_) { dispatch(GenerateRandom) }
  let reset = fn(_) { dispatch(ResetCount) }

  let current_count = int.to_string(count)

  render(
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
  let view = component(inc_random_reset_counter, Nil)

  let spkt = connect(view)

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")

  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 1")

  let spkt = render_event(spkt, ClickEvent, "increment")

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 2")

  let spkt = render_event(spkt, ClickEvent, "reset")

  let #(spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 0")

  let spkt = render_event(spkt, ClickEvent, "random")

  // reducer commands are run asynchonously so we need to wait for the command to be processed
  // before we can test the initial state
  test_helpers.wait_until(
    fn() {
      let #(_spkt, rendered) = render_html(spkt)

      rendered
      |> string.starts_with("current count is: 42")
    },
    1000,
  )

  let #(_spkt, rendered) = render_html(spkt)

  let assert True =
    rendered
    |> string.starts_with("current count is: 42")
}

fn count_down(ctx: Context, _props) {
  // Define a reducer to handle events and update the state
  use ctx, Model(count: count), dispatch <- reducer(
    ctx,
    fn(_) { Model(42) },
    update,
  )

  // Define event handlers
  let start = fn(_) { dispatch(CountDown(count)) }

  let current_count = int.to_string(count)

  render(
    ctx,
    fragment([
      text("current count is: "),
      text(current_count),
      button([id("start"), on_click(start)], [text("start")]),
    ]),
  )
}

pub fn reducer_should_run_cmds_recursively_test() {
  let view = component(count_down, Nil)

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
    fn(dispatch) {
      generate_random(dispatch)

      Model(0)
    },
    update,
  )

  // Define event handlers
  let reset = fn(_) { dispatch(ResetCount) }

  let current_count = int.to_string(count)

  render(
    ctx,
    fragment([
      text("current count is: "),
      text(current_count),
      button([id("reset"), on_click(reset)], [text("reset")]),
    ]),
  )
}

pub fn reducer_should_initialize_with_cmds_test() {
  let view = component(component_with_initial_cmds, Nil)

  let spkt = connect(view)

  // reducer commands are run asynchonously so we need to wait for the command to be processed
  // before we can test the initial state
  test_helpers.wait_until(
    fn() {
      let #(_spkt, rendered) = render_html(spkt)

      rendered
      |> string.starts_with("current count is: 42")
    },
    1000,
  )

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
