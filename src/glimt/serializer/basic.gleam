import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic}
import gleam/string.{inspect}
import gleam/erlang.{format}
import gleam/erlang/process.{Pid}
import glimt/log_message.{
  ALL, DEBUG, ERROR, FATAL, INFO, LogLevel, LogMessage, NONE, TRACE, WARNING,
  level_string,
}
import glimt/style.{Style, default_color_style}

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

/// Basic serializer that writes the message as one line separated by `|`
/// > NOTE: data and context will not be serialized
pub fn basic_serializer(log_message: LogMessage(data, context, Dynamic)) {
  basic_serializer_with_style(default_color_style, log_message)
}

/// Basic serializer that writes the message as one line separated by `|`
/// Add one of the default (or a custom) `Style` for coloring the different segments
/// > NOTE: data and context will not be serialized
pub fn basic_serializer_with_style(
  style: Style(LogLevel),
  log_message: LogMessage(data, context, Dynamic),
) {
  let assert LogMessage(
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
  let styled_time = style.style_time(time)
  let styled_level =
    level_string(level)
    |> style.style_level(level)
  let styled_message = message
  let error_string = case error {
    Some(err) -> " | " <> inspect(err)
    None -> ""
  }
  let styled_name =
    name
    |> full_name(pid, instance_name, instance_pid)
    |> style.style_name()
  styled_time <> " | " <> styled_level <> " | " <> styled_name <> " | " <> styled_message <> error_string
}
