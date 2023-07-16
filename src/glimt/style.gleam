// import galant.{
//   dim, magenta, open, placeholder, start_bold, start_cyan, start_dim,
//   start_green, start_red, start_yellow, to_string_styler,
// }
import gleam_community/ansi.{bold, cyan, dim, green, magenta, red, yellow}
import glimt/log_message.{
  ALL, DEBUG, ERROR, FATAL, INFO, LogLevel, NONE, TRACE, WARNING,
}
import glimt/erlang_logger/level.{
  Alert, Critical, Debug, Emergency, Error, Info, Level, Notice, Warning,
}

pub fn style_level(s: String, level: LogLevel) {
  case level {
    ALL -> style_plain(s)
    NONE -> style_plain(s)
    TRACE -> style_trace(s)
    DEBUG -> style_debug(s)
    INFO -> style_info(s)
    WARNING -> style_warning(s)
    ERROR -> style_error(s)
    FATAL -> style_fatal(s)
  }
}

pub fn style_erlang_level(s: String, level: Level) {
  case level {
    Emergency -> style_fatal(s)
    Alert -> style_fatal(s)
    Critical -> style_fatal(s)
    Error -> style_error(s)
    Warning -> style_warning(s)
    Notice -> style_info(s)
    Info -> style_debug(s)
    Debug -> style_trace(s)
  }
}

pub fn style_trace(s: String) {
  s
  |> dim()
  |> cyan()
}

pub fn style_debug(s: String) {
  s
  |> cyan()
}

pub fn style_info(s: String) {
  s
  |> green()
}

pub fn style_error(s: String) {
  s
  |> red()
}

pub fn style_fatal(s: String) {
  s
  |> bold()
  |> red()
}

pub fn style_warning(s: String) {
  s
  |> yellow()
}

pub fn style_plain(s: String) {
  s
}

pub fn style_name(name: String) {
  name
  |> magenta()
}

pub fn style_time(time: String) {
  time
  |> dim()
}
