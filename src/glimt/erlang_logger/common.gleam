import gleam/dynamic.{Dynamic}
import gleam/erlang/atom.{Atom}

pub fn a(string: String) -> Atom {
  atom.create_from_string(string)
}

pub external fn set_handler_config(
  handler_id: Atom,
  config_item: Atom,
  config: #(Atom, Dynamic),
) -> Nil =
  "logger" "set_handler_config"
