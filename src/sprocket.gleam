import docs

pub fn main() {
  // Currently, gleam export erlang-shipment requires a main function in
  // in the project's main module. It would be nice to be able to specify
  // a specific module to run, but for now, we'll just call the main function
  docs.main()
}
