import gleam/dynamic.{Dynamic, string}
import gleam/erlang
import gleam/erlang/atom.{Atom}

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
