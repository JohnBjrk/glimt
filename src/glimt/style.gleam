// import galant.{
//   dim, magenta, open, placeholder, start_bold, start_cyan, start_dim,
//   start_green, start_red, start_yellow, to_string_styler,
// }
import gleam_community/ansi.{bold,
  cyan, dim, green, magenta, red, reset, yellow}

pub fn style_trace() {
  fn(s: String) {
    s
    |> dim()
    |> cyan()
  }
}

pub fn style_debug() {
  fn(s: String) {
    s
    |> cyan()
  }
}

pub fn style_info() {
  fn(s: String) {
    s
    |> green()
  }
}

pub fn style_error() {
  fn(s: String) {
    s
    |> red()
  }
}

pub fn style_fatal() {
  fn(s: String) {
    s
    |> bold()
    |> red()
  }
}

pub fn style_warning() {
  fn(s: String) {
    s
    |> yellow()
  }
}

pub fn style_plain() {
  fn(s: String) { s }
}

pub fn style_name(name: String) {
  name
  |> magenta()
}

pub fn style_time(time: String) {
  time
  |> dim()
}
