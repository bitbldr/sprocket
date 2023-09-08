import gleam/int
import gleam/float
import gleam/erlang
import gleam/option.{Some}
import sprocket/context.{Context}
import sprocket/component.{render}
import sprocket/hooks.{WithDeps, dep}
import sprocket/hooks/reducer.{reducer}
import sprocket/hooks/effect.{effect}
import sprocket/html/attributes.{xmlns, xmlns_xlink}
import sprocket/html/svg/elements.{circle, g, line, path, svg}
import sprocket/html/svg/attributes.{
  class, cx, cy, d, fill, height, id, r, stroke, stroke_miterlimit, stroke_width,
  transform, version, view_box, width, x, x1, x2, xml_space, y, y1, y2,
} as svg_attributes
import sprocket/internal/utils/timer.{interval}

type Model {
  Model(time: Int, timezone: String)
}

type Msg {
  UpdateTime(Int)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    UpdateTime(time) -> {
      Model(..model, time: time)
    }
  }
}

fn initial() -> Model {
  Model(time: erlang.system_time(erlang.Second), timezone: "UTC")
}

pub type AnalogClockProps {
  AnalogClockProps
}

pub fn analog_clock(ctx: Context, _props: AnalogClockProps) {
  // let AnalogClockProps() = props

  // Define a reducer to handle events and update the state
  use ctx, Model(time: time, ..), dispatch <- reducer(ctx, initial(), update)

  // Example effect that runs whenever the `time` variable changes and has a cleanup function
  use ctx <- effect(
    ctx,
    fn() {
      let interval_duration = 1000

      let update_time = fn() {
        dispatch(UpdateTime(erlang.system_time(erlang.Second)))
      }

      update_time()

      let cancel = interval(interval_duration, update_time)

      Some(fn() { cancel() })
    },
    WithDeps([dep(time)]),
  )

  let #(hours, minutes, seconds) = clock_time(time)

  let hours = case hours > 12 {
    True -> hours - 12
    False -> hours
  }
  let minutes = { minutes * 60 } + seconds
  let hours = { hours * 3600 } + minutes

  let clock_second_hand_transform =
    "rotate(" <> float.to_string(360.0 *. { int.to_float(seconds) /. 60.0 }) <> ",192,192)"
  let clock_minute_hand_transform =
    "rotate(" <> float.to_string(360.0 *. { int.to_float(minutes) /. 3600.0 }) <> ",192,192)"
  let clock_hour_hand_transform =
    "rotate(" <> float.to_string(360.0 *. { int.to_float(hours) /. 43_200.0 }) <> ",192,192)"

  render(
    ctx,
    [
      svg(
        [
          version("1.1"),
          xmlns("http://www.w3.org/2000/svg"),
          xmlns_xlink("http://www.w3.org/1999/xlink"),
          x("0px"),
          y("0px"),
          width("384px"),
          height("384px"),
          view_box("0 0 384 384"),
          xml_space("preserve"),
          transform("scale(0.5)"),
        ],
        [
          path(
            [
              class("clock-frame"),
              d(
                "M192,0C85.961,0,0,85.961,0,192s85.961,192,192,192s192-85.961,192-192S298.039,0,192,0zM315.037,315.037c-9.454,9.454-19.809,17.679-30.864,24.609l-14.976-25.939l-10.396,6l14.989,25.964c-23.156,12.363-48.947,19.312-75.792,20.216V336h-12v29.887c-26.845-0.903-52.636-7.854-75.793-20.217l14.989-25.963l-10.393-6l-14.976,25.938c-11.055-6.931-21.41-15.154-30.864-24.608s-17.679-19.809-24.61-30.864l25.939-14.976l-6-10.396l-25.961,14.99C25.966,250.637,19.017,224.846,18.113,198H48v-12H18.113c0.904-26.844,7.853-52.634,20.216-75.791l25.96,14.988l6.004-10.395L44.354,99.827c6.931-11.055,15.156-21.41,24.61-30.864s19.809-17.679,30.864-24.61l14.976,25.939l10.395-6L110.208,38.33C133.365,25.966,159.155,19.017,186,18.113V48h12V18.113c26.846,0.904,52.635,7.853,75.792,20.216l-14.991,25.965l10.395,6l14.978-25.942c11.056,6.931,21.41,15.156,30.865,24.611c9.454,9.454,17.679,19.808,24.608,30.863l-25.94,14.976l6,10.396l25.965-14.99c12.363,23.157,19.312,48.948,20.218,75.792H336v12h29.887c-0.904,26.845-7.853,52.636-20.216,75.792l-25.964-14.989l-6.002,10.396l25.941,14.978C332.715,295.229,324.491,305.583,315.037,315.037z",
              ),
            ],
            [],
          ),
          line(
            [
              class("clock-hour-hand"),
              id("clock-hour-hand"),
              transform(clock_hour_hand_transform),
              fill("none"),
              stroke("#000000"),
              stroke_width("18"),
              stroke_miterlimit("10"),
              x1("192"),
              y1("192"),
              x2("192"),
              y2("87.5"),
            ],
            [],
          ),
          line(
            [
              class("clock-minute-hand"),
              id("anim-clock-minute-hand"),
              transform(clock_minute_hand_transform),
              fill("none"),
              stroke("#000000"),
              stroke_width("12"),
              stroke_miterlimit("10"),
              x1("192"),
              y1("192"),
              x2("192"),
              y2("54"),
            ],
            [],
          ),
          circle([class("clock-axis"), cx("192"), cy("192"), r("9")], []),
          g(
            [
              class("clock-second-hand"),
              id("anim-clock-second-hand"),
              transform(clock_second_hand_transform),
            ],
            [
              line(
                [
                  class("clock-second-hand-arm"),
                  fill("none"),
                  stroke("#D53A1F"),
                  stroke_width("4"),
                  stroke_miterlimit("10"),
                  x1("192"),
                  y1("192"),
                  x2("192"),
                  y2("28.5"),
                ],
                [],
              ),
              circle(
                [
                  class("clock-second-hand-axis"),
                  fill("#D53A1F"),
                  cx("192"),
                  cy("192"),
                  r("4.5"),
                ],
                [],
              ),
            ],
          ),
        ],
      ),
    ],
  )
}

@external(erlang, "Elixir.FFIUtils", "clock_time")
fn clock_time(a: Int) -> #(Int, Int, Int)
