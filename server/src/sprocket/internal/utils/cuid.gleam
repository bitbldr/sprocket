//// Temporarily Forked from: https://github.com/rvcas/ids/blob/main/src/ids/cuid.gleam
//// Updated to support gleam_erlang and gleam_otp > 1.0.0
//// 
//// A module for generating CUIDs (Collision-resistant Unique Identifiers).
//// The implementation requires a counter, so an actor is used to keep track
//// of that state. This means before generating a CUID, an actor needs to be
//// started and all work is done via a channel.
////
//// Slugs are also supported.
////

import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/otp/actor.{type Next}
import gleam/result
import gleam/string
import sprocket/internal/utils/time.{Millisecond, system_time}

/// The messages handled by the actor.
///
/// The actor shouldn't be called directly so this type is opaque.
pub opaque type Message {
  Generate(reply_with: Subject(String))
  GenerateSlug(reply_with: Subject(String))
}

/// The internal state of the actor.
///
/// The state keeps track of a counter and a fingerprint.
/// Both are used when generating a CUID.
pub opaque type State {
  State(count: Int, fingerprint: String)
}

/// Starts a CUID generator.
pub fn start() -> Result(Subject(Message), actor.StartError) {
  actor.new(State(0, get_fingerprint()))
  |> actor.on_message(handle_msg)
  |> actor.start()
  |> result.map(fn(started) { started.data })
}

/// Generates a CUID using the given channel.
///
/// ### Usage
/// ```gleam
/// import ids/cuid
///
/// let assert Ok(channel) = cuid.start()
///
/// let id: String = cuid.generate(channel)
///
/// let slug: String = cuid.slug(channel)
/// ```
pub fn generate(channel: Subject(Message)) -> String {
  actor.call(channel, 1000, Generate)
}

/// Checks if a string is a CUID.
pub fn is_cuid(id: String) -> Bool {
  string.starts_with(id, "c")
}

/// Generates a slug using the given channel.
pub fn slug(channel: Subject(Message)) -> String {
  actor.call(channel, 1000, GenerateSlug)
}

/// Checks if a string is a slug.
pub fn is_slug(slug: String) -> Bool {
  let slug_length = string.length(slug)

  slug_length >= 7 && slug_length <= 10
}

const base: Int = 36

fn handle_msg(state: State, msg: Message) -> Next(State, Message) {
  case msg {
    Generate(reply_with) -> {
      let id =
        format_id([
          "c",
          timestamp(),
          format_count(state.count),
          state.fingerprint,
          random_block(),
          random_block(),
        ])
      actor.send(reply_with, id)
      actor.continue(State(..state, count: new_count(state.count)))
    }
    GenerateSlug(reply_with) -> {
      let slug =
        format_id([
          timestamp()
            |> string.slice(-2, 2),
          format_count(state.count)
            |> string.slice(-4, 4),
          string.concat([
            string.slice(state.fingerprint, 0, 1),
            string.slice(state.fingerprint, -1, 1),
          ]),
          random_block()
            |> string.slice(-2, 2),
        ])
      actor.send(reply_with, slug)
      actor.continue(State(..state, count: new_count(state.count)))
    }
  }
}

const block_size: Int = 4

const discrete_values: Int = 1_679_616

fn format_id(id_data: List(String)) -> String {
  id_data
  |> string.concat()
  |> string.lowercase()
}

fn new_count(count: Int) -> Int {
  case count < discrete_values {
    True -> count + 1
    False -> 0
  }
}

fn timestamp() -> String {
  let secs = system_time(Millisecond)

  secs
  |> int.to_base36()
}

fn format_count(num: Int) -> String {
  num
  |> int.to_base36()
  |> string.pad_start(to: block_size, with: "0")
}

type CharList

@external(erlang, "os", "getpid")
fn os_getpid() -> CharList

@external(erlang, "erlang", "list_to_binary")
fn char_list_to_string(cl: CharList) -> String

@external(erlang, "net_adm", "localhost")
fn net_adm_localhost() -> List(Int)

fn get_fingerprint() -> String {
  let operator = base * base
  let assert Ok(pid) =
    os_getpid()
    |> char_list_to_string()
    |> int.parse()

  let id = pid % operator * operator

  let localhost = net_adm_localhost()
  let sum =
    localhost
    |> list.fold(from: 0, with: fn(char, acc) { char + acc })

  let hostid = { sum + list.length(localhost) + base } % operator

  id + hostid
  |> int.to_base36()
}

@external(erlang, "rand", "uniform")
fn rand_uniform(n: Int) -> Int

fn random_block() -> String {
  rand_uniform(discrete_values - 1)
  |> int.to_base36()
  |> string.pad_start(to: block_size, with: "0")
}
