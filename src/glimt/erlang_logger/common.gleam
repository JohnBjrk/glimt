import gleam/dynamic.{Dynamic, from, string}
import gleam/erlang
import gleam/erlang/atom.{Atom}
import gleam/erlang/charlist.{Charlist, to_string}

pub fn a(string: String) -> Atom {
  atom.create_from_string(string)
}

pub fn format_dynamic(dynamic_value: Dynamic) {
  case string(dynamic_value) {
    Ok(string_value) -> string_value
    _ -> erlang.format(dynamic_value)
  }
}

pub external fn set_handler_config(
  handler_id: Atom,
  config_item: Atom,
  config: #(Atom, Dynamic),
) -> Nil =
  "logger" "set_handler_config"

pub external fn built_in_format(log_event: Dynamic, config: Dynamic) -> String =
  "logger_formatter" "format"

pub fn time_to_string(time: Int) -> String {
  system_time_to_rfc3339(time, from([#(a("unit"), a("microsecond"))]))
  |> to_string()
}

external fn system_time_to_rfc3339(time: Int, options: Dynamic) -> Charlist =
  "calendar" "system_time_to_rfc3339"
