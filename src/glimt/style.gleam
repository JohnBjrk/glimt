import galant.{
  dim, magenta, open, placeholder, start_bold, start_cyan, start_dim,
  start_green, start_red, start_yellow, to_string_styler,
}

pub fn style_trace() {
  open()
  |> start_dim()
  |> start_cyan()
  |> placeholder()
  |> to_string_styler()
}

pub fn style_debug() {
  open()
  |> start_cyan()
  |> placeholder()
  |> to_string_styler()
}

pub fn style_info() {
  open()
  |> start_green()
  |> placeholder()
  |> to_string_styler()
}

pub fn style_error() {
  open()
  |> start_red()
  |> placeholder()
  |> to_string_styler()
}

pub fn style_fatal() {
  open()
  |> start_bold()
  |> start_red()
  |> placeholder()
  |> to_string_styler()
}

pub fn style_warning() {
  open()
  |> start_yellow()
  |> placeholder()
  |> to_string_styler()
}

pub fn style_plain() {
  open()
  |> placeholder()
  |> to_string_styler()
}

pub fn style_name(name: String) {
  open()
  |> magenta(name)
  |> galant.to_string()
}

pub fn style_time(time: String) {
  open()
  |> dim(time)
  |> galant.to_string()
}
