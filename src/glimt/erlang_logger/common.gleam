//// Common functions used by the `logger`, `basic_formatter` and `json_formatter`

import gleam/dynamic.{Dynamic, from, string}
import gleam/erlang
import gleam/erlang/atom.{Atom}
import gleam/erlang/charlist.{Charlist, to_string}

/// Shorthand for creating an `Atom`
/// Equivalent to `atom.create_from_string()`
pub fn a(string: String) -> Atom {
  atom.create_from_string(string)
}

/// String representation of a `Dynamic` value.
/// If the dynamic value is a String it will be returned, otherwise the value
/// will be converted using `erlang.format`
pub fn format_dynamic(dynamic_value: Dynamic) -> String {
  case string(dynamic_value) {
    Ok(string_value) -> string_value
    _ -> erlang.format(dynamic_value)
  }
}

/// Set config for handler with `handler_id`
@external(erlang, "logger", "set_handler_config")
pub fn set_handler_config(handler_id handler_id: Atom, config_item config_item: Atom, config config: #(
    Atom,
    Dynamic,
  )) -> Nil

/// Calls the standard erlang formatter. Useful when a formatter is unable to
/// format the log_event
pub fn built_in_format(log_event: Dynamic, config: Dynamic) -> String {
  logger_format(log_event, config)
  |> to_string()
}

@external(erlang, "logger_formatter", "format")
pub fn logger_format(log_event log_event: Dynamic, config config: Dynamic) -> Charlist

/// Converts a epoch microsecond value to a rfc3339 string
pub fn time_to_string(time: Int) -> String {
  system_time_to_rfc3339(
    time,
    from([#(a("unit"), from(a("microsecond"))), #(a("offset"), from(0))]),
  )
  |> to_string()
}

@external(erlang, "calendar", "system_time_to_rfc3339")
fn system_time_to_rfc3339(time time: Int, options options: Dynamic) -> Charlist
