import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import gleam/string.{inspect}
import gleam/erlang.{format}
import gleam/erlang/process.{Pid}
import glimt/log_message.{
  ALL, DEBUG, ERROR, FATAL, INFO, LogLevel, LogMessage, NONE, TRACE, WARNING,
  level_string,
}
import galant.{
  dim, magenta, open, placeholder, start_bold, start_cyan, start_dim,
  start_green, start_red, start_yellow, to_string_styler,
}

pub fn level_symbol(log_level: LogLevel) {
  case log_level {
    ALL -> "ALL"
    TRACE -> "🔍"
    DEBUG -> "🐛"
    INFO -> "ℹ️"
    WARNING -> "⚠️"
    ERROR -> "❌"
    FATAL -> "🔥"
    NONE -> "NONE"
  }
}

fn style_trace() {
  open()
  |> start_dim()
  |> start_cyan()
  |> placeholder()
  |> to_string_styler()
}

fn style_debug() {
  open()
  |> start_cyan()
  |> placeholder()
  |> to_string_styler()
}

fn style_info() {
  open()
  |> start_green()
  |> placeholder()
  |> to_string_styler()
}

fn style_error() {
  open()
  |> start_red()
  |> placeholder()
  |> to_string_styler()
}

fn style_fatal() {
  open()
  |> start_bold()
  |> start_red()
  |> placeholder()
  |> to_string_styler()
}

fn style_warning() {
  open()
  |> start_yellow()
  |> placeholder()
  |> to_string_styler()
}

fn style_plain() {
  open()
  |> placeholder()
  |> to_string_styler()
}

fn style_level(log_level: LogLevel) {
  case log_level {
    ALL -> style_plain()
    TRACE -> style_trace()
    DEBUG -> style_debug()
    INFO -> style_info()
    WARNING -> style_warning()
    ERROR -> style_error()
    FATAL -> style_fatal()
    NONE -> style_plain()
  }
}

fn style_name(name: String) {
  open()
  |> magenta(name)
  |> galant.to_string()
}

fn style_time(time: String) {
  open()
  |> dim(time)
  |> galant.to_string()
}

fn full_name(
  name: String,
  pid: Pid,
  instance_name: Option(String),
  instance_pid: Option(Pid),
) {
  case instance_name, instance_pid {
    Some(instance_name), Some(instance_pid) ->
      name <> "(" <> format(pid) <> ")/" <> instance_name <> "(" <> format(
        instance_pid,
      ) <> ")"
    Some(instance_name), None ->
      name <> "(" <> format(pid) <> ")/" <> instance_name
    None, Some(instance_pid) ->
      name <> "(" <> format(pid) <> ")/" <> "???" <> "(" <> format(instance_pid) <> ")"
    None, None -> name <> "(" <> format(pid) <> ")"
  }
}

pub fn basic_serializer(log_message: LogMessage(data, Dynamic)) {
  assert LogMessage(
    time: time,
    name: name,
    pid: pid,
    instance_name: instance_name,
    instance_pid: instance_pid,
    level: level,
    message: message,
    error: error,
    ..,
  ) = log_message
  let styled_time = style_time(time)
  let styled_level =
    level_string(level)
    |> style_level(level)
  let styled_message = message
  let error_string = case error {
    Some(err) -> " | " <> inspect(err)
    None -> ""
  }
  case name {
    Some(name) -> {
      let styled_name =
        name
        |> full_name(pid, instance_name, instance_pid)
        |> style_name()
      styled_time <> " | " <> styled_level <> " | " <> styled_name <> " | " <> styled_message <> error_string
    }
    None -> {
      let styled_name =
        "anonymous"
        |> full_name(pid, instance_name, instance_pid)
        |> style_name()
      styled_time <> " | " <> styled_level <> " | " <> styled_name <> " | " <> styled_message <> error_string
    }
  }
}
