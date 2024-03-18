import gleam_community/ansi.{bold, cyan, dim, green, magenta, red, yellow}
import glimt/log_message.{
  type LogLevel, ALL, DEBUG, ERROR, FATAL, INFO, NONE, TRACE, WARNING,
}
import glimt/erlang_logger/level.{
  type Level, Alert, Critical, Debug, Emergency, Error, Info, Notice, Warning,
}

pub type Style(level) {
  Style(
    style_level: fn(String, level) -> String,
    style_name: fn(String) -> String,
    style_time: fn(String) -> String,
  )
}

pub const default_color_style = Style(style_level, style_name, style_time)

pub const default_erlang_color_style = Style(
  style_erlang_level,
  style_name,
  style_time,
)

pub const default_plain_style = Style(plain_level, style_plain, style_plain)

pub fn plain_level(s: String, _level: level) {
  s
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

fn style_trace(s: String) {
  s
  |> dim()
  |> cyan()
}

fn style_debug(s: String) {
  s
  |> cyan()
}

fn style_info(s: String) {
  s
  |> green()
}

fn style_error(s: String) {
  s
  |> red()
}

fn style_fatal(s: String) {
  s
  |> bold()
  |> red()
}

fn style_warning(s: String) {
  s
  |> yellow()
}

fn style_plain(s: String) {
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
