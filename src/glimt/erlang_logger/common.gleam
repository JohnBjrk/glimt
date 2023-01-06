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
pub external fn set_handler_config(
  handler_id: Atom,
  config_item: Atom,
  config: #(Atom, Dynamic),
) -> Nil =
  "logger" "set_handler_config"

/// Calls the standard erlang formatter. Useful when a formatter is unable to
/// format the log_event
pub external fn built_in_format(log_event: Dynamic, config: Dynamic) -> String =
  "logger_formatter" "format"

/// Converts a epoch microsecond value to a rfc3339 string
pub fn time_to_string(time: Int) -> String {
  system_time_to_rfc3339(time, from([#(a("unit"), a("microsecond"))]))
  |> to_string()
}

external fn system_time_to_rfc3339(time: Int, options: Dynamic) -> Charlist =
  "calendar" "system_time_to_rfc3339"
