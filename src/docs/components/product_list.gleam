import gleam/int
import gleam/list
import gleam/float
import gleam/option.{None, Option, Some}
import sprocket/context.{Context, Element}
import sprocket/component.{component, render}
import sprocket/hooks.{OnMount, WithDeps, dep}
import sprocket/hooks/reducer.{reducer}
import sprocket/hooks/state.{state}
import sprocket/hooks/callback.{callback}
import sprocket/internal/identifiable_callback.{CallbackFn}
import sprocket/html.{
  button, button_text, div, div_text, h5_text, i, img, keyed, li, text, ul,
}
import sprocket/html/attributes.{alt, class, on_click, role, src}

pub type Product {
  Product(
    id: Int,
    name: String,
    description: String,
    img_url: String,
    qty: String,
    price: Float,
  )
}

pub type ProductProps {
  ProductProps(product: Product, on_hide: fn(Int) -> Nil)
}

pub fn product_card(product: Product, actions: Option(List(Element))) {
  let Product(
    name: name,
    description: description,
    img_url: img_url,
    qty: qty,
    price: price,
    ..,
  ) = product
  div(
    [
      class(
        "flex flex-row bg-white border border-gray-200 rounded-lg shadow dark:bg-gray-800 dark:border-gray-700",
      ),
    ],
    [
      div(
        [class("w-1/3 rounded-l-lg overflow-hidden")],
        [
          img([
            class("object-cover h-56 w-full"),
            src(img_url),
            alt("product image"),
          ]),
        ],
      ),
      div(
        [class("flex-1 flex flex-col p-5")],
        [
          div(
            [class("flex-1 flex flex-row")],
            [
              div(
                [class("flex-1")],
                [
                  h5_text(
                    [
                      class(
                        "text-xl font-semibold tracking-tight text-gray-900 dark:text-white",
                      ),
                    ],
                    name,
                  ),
                  div_text([class("py-2 text-gray-500")], description),
                ],
              ),
              div(
                [],
                [
                  div(
                    [class("flex-1 flex flex-col text-right")],
                    [
                      div_text(
                        [
                          class(
                            "text-xl font-bold text-gray-900 dark:text-white",
                          ),
                        ],
                        "$" <> float.to_string(price),
                      ),
                      div_text([class("text-sm text-gray-500")], qty),
                    ],
                  ),
                ],
              ),
            ],
          ),
          case actions {
            None -> div([], [])
            Some(actions) ->
              div([class("flex flex flex-row justify-end")], actions)
          },
        ],
      ),
    ],
  )
}

pub fn product(ctx: Context, props: ProductProps) {
  let ProductProps(product, on_hide) = props

  use ctx, in_cart, set_in_cart <- state(ctx, False)

  use ctx, toggle_in_cart <- callback(
    ctx,
    CallbackFn(fn() {
      set_in_cart(!in_cart)
      Nil
    }),
    WithDeps([dep(in_cart)]),
  )

  use ctx, on_hide <- callback(
    ctx,
    CallbackFn(fn() {
      on_hide(product.id)
      Nil
    }),
    OnMount,
  )

  render(
    ctx,
    [
      product_card(
        product,
        Some([
          button_text(
            [
              class(
                "text-blue-700 hover:text-blue-800 hover:underline focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:text-blue-600 dark:hover:text-blue-700 dark:focus:ring-blue-800 mr-2",
              ),
              on_click(on_hide),
            ],
            "Not Interested",
          ),
          ..case in_cart {
            True -> [
              button(
                [
                  class(
                    "text-white bg-green-700 hover:bg-green-800 focus:ring-4 focus:outline-none focus:ring-green-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-green-600 dark:hover:bg-green-700 dark:focus:ring-green-800",
                  ),
                  on_click(toggle_in_cart),
                ],
                [
                  i([class("fa-solid fa-check mr-2")], []),
                  text("Added to Cart!"),
                ],
              ),
            ]
            False -> [
              button(
                [
                  class(
                    "text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800",
                  ),
                  on_click(toggle_in_cart),
                ],
                [
                  i([class("fa-solid fa-cart-shopping mr-2")], []),
                  text("Add to Cart"),
                ],
              ),
            ]
          }
        ]),
      ),
    ],
  )
}

type Model {
  Model(hidden: List(Int))
}

type Msg {
  NoOp
  Hide(Int)
  Reset
}

fn update(model: Model, msg: Msg) {
  case msg {
    NoOp -> model
    Hide(id) -> Model(hidden: [id, ..model.hidden])
    Reset -> Model(hidden: [])
  }
}

fn initial() {
  Model(hidden: [])
}

pub type ProductListProps {
  ProductListProps(products: List(Product))
}

pub fn product_list(ctx: Context, props: ProductListProps) {
  let ProductListProps(products: products) = props

  use ctx, Model(hidden), dispatch <- reducer(ctx, initial(), update)

  use ctx, reset <- callback(ctx, CallbackFn(fn() { dispatch(Reset) }), OnMount)

  render(
    ctx,
    [
      div(
        [],
        [
          ul(
            [role("list"), class("flex flex-col")],
            products
            |> list.filter_map(fn(p) {
              case list.contains(hidden, p.id) {
                True -> Error(Nil)
                False ->
                  Ok(keyed(
                    int.to_string(p.id),
                    li(
                      [class("py-3 mr-4")],
                      [
                        component(
                          product,
                          ProductProps(
                            product: p,
                            on_hide: fn(_) { dispatch(Hide(p.id)) },
                          ),
                        ),
                      ],
                    ),
                  ))
              }
            }),
          ),
          ..case list.is_empty(hidden) {
            True -> []
            False -> [
              button(
                [
                  class(
                    "mt-5 text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 text-center dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800",
                  ),
                  on_click(reset),
                ],
                [
                  text("Show Hidden ("),
                  text(int.to_string(list.length(hidden))),
                  text(")"),
                ],
              ),
            ]
          }
        ],
      ),
    ],
  )
}

pub fn example_products() {
  [
    Product(
      id: 2255,
      name: "Eco-Friendly Bamboo Cutting Board",
      description: "This sustainable bamboo cutting board is perfect for slicing and dicing vegetables, fruits, and meats. The natural antibacterial properties of bamboo ensure a hygienic cooking experience.",
      img_url: "https://images.pexels.com/photos/6489734/pexels-photo-6489734.jpeg",
      qty: "12 x 8 inches",
      price: 24.99,
    ),
    Product(
      id: 2256,
      name: "Wireless Bluetooth Earbuds",
      description: "Enjoy true wireless freedom with these Bluetooth earbuds. The ergonomic design provides a comfortable fit, and the advanced Bluetooth 5.0 technology ensures a stable connection with your devices. With noise-cancellation and high-quality sound, these earbuds are perfect for music lovers and hands-free calls. Comes with a portable charging case for extended use.",
      img_url: "https://images.pexels.com/photos/8380433/pexels-photo-8380433.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "1 set",
      price: 49.99,
    ),
    Product(
      id: 2257,
      name: "Vintage Leather Messenger Bag",
      description: "Handcrafted from high quality vegan leather, this messenger bag is a perfect blend of style and functionality",
      img_url: "https://images.pexels.com/photos/1152077/pexels-photo-1152077.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "1 bag",
      price: 89.99,
    ),
    Product(
      id: 2258,
      name: "Fitness Tracker Smart Watch",
      description: "Stay on top of your fitness goals with this feature-packed smartwatch. It tracks your steps, heart rate, sleep patterns, and various exercises. The color touchscreen display provides easy navigation through your notifications, calls, and messages. It's water-resistant and comes with a long-lasting battery for continuous use.",
      img_url: "https://images.pexels.com/photos/437036/pexels-photo-437036.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "1 watch",
      price: 69.99,
    ),
    Product(
      id: 2259,
      name: "Organic Aromatherapy Candle",
      description: "Create a fresh ambiance with this organic aromatherapy candle. Hand-poured with pure essential oils, the fresh scent of citrus will brighten up your room.",
      img_url: "https://images.pexels.com/photos/7260249/pexels-photo-7260249.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "1 candle",
      price: 19.99,
    ),
  ]
}

pub fn example_coffee_products() {
  [
    Product(
      id: 2255,
      name: "Morning Bliss",
      description: "A medium-bodied coffee with a balanced acidity that pairs perfectly with breakfast.",
      img_url: "https://images.pexels.com/photos/17032151/pexels-photo-17032151/free-photo-of-a-cup-of-espresso-on-a-table-by-the-window.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "12 oz bag",
      price: 12.99,
    ),
    Product(
      id: 2256,
      name: "Sunset Serenade",
      description: "A mix of Ethiopian and Kenyan beans, carefully selected for their bright berry undertones and floral aroma and roasted at a medium-dark level.",
      img_url: "https://images.pexels.com/photos/9716818/pexels-photo-9716818.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "10 oz bag",
      price: 14.99,
    ),
    Product(
      id: 2257,
      name: "Island Breeze",
      description: "A unique fusion of Indonesian Sumatra and Hawaiian Kona beans that are dark-roasted",
      img_url: "https://images.pexels.com/photos/2252307/pexels-photo-2252307.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "8 oz bag",
      price: 17.99,
    ),
    Product(
      id: 2258,
      name: "Zen Garden Blend",
      description: "A mindful combination of shade-grown Colombian and Costa Rican beans, carefully roasted to a medium-light profile.",
      img_url: "https://images.pexels.com/photos/539694/pexels-photo-539694.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "16 oz bag",
      price: 15.99,
    ),
    Product(
      id: 2259,
      name: "Mocha Madness",
      description: "A decadent blend of Central American beans blended with premium cocoa nibs that are medium-roasted.",
      img_url: "https://images.pexels.com/photos/2396220/pexels-photo-2396220.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2",
      qty: "12 oz bag",
      price: 19.99,
    ),
  ]
}
