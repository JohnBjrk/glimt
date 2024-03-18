import gleam/dynamic.{type Dynamic, from}
import gleam/list.{append, map}
import gleam/dict.{type Dict}
import gleam/string.{inspect}
import gleam/option.{type Option, Some}
import glimt/log_message.{
  type LogLevel, type LogMessage, ALL, DEBUG, ERROR, FATAL, INFO, LogMessage,
  NONE, TRACE, WARNING,
}
import glimt/erlang_logger/level.{
  type Level, Critical, Debug, Info, Notice, Warning,
}
import glimt/erlang_logger/common.{a}
import gleam/erlang/atom.{type Atom}

/// Dispatcher that send the `LogMessage` to the erlang built-in logger
/// Logs the message as a string
pub fn logger_dispatch(log_message: LogMessage(data, context, Dynamic)) {
  logger_log_message(
    map_level(log_message.level),
    log_message.message,
    create_meta(log_message),
  )
}

/// Dispatcher that send the `LogMessage` to the erlang built-in logger
/// Logs the message as `msg` field in a report
/// Merges `data` and `context` into the report
pub fn logger_report_dispatch(
  log_message: LogMessage(
    List(#(String, String)),
    List(#(String, String)),
    Dynamic,
  ),
) {
  let data_report = as_report_list(log_message.data)
  let context_report = as_report_list(log_message.context)
  let combined_report = append(data_report, context_report)
  let report = [#(a("msg"), from(log_message.message)), ..combined_report]
  logger_log_report(
    map_level(log_message.level),
    dict.from_list(report),
    create_meta(log_message),
  )
}

fn create_meta(log_message: LogMessage(data, context, Dynamic)) {
  let meta_with_name = [#(a("loggername"), from(log_message.name))]
  let meta = case log_message.error {
    Some(error) -> [#(a("error"), from(inspect(error))), ..meta_with_name]
    _ -> meta_with_name
  }
  dict.from_list(meta)
}

fn as_report_list(data: Option(List(#(String, String)))) {
  case data {
    Some(data) ->
      data
      |> map(fn(entry) {
        let assert #(key, value) = entry
        #(a(key), from(value))
      })
    _ -> []
  }
}

fn map_level(log_level: LogLevel) -> Level {
  case log_level {
    NONE -> Debug
    ALL -> Debug
    TRACE -> Debug
    DEBUG -> Info
    INFO -> Notice
    WARNING -> Warning
    ERROR -> level.Error
    FATAL -> Critical
  }
}

@external(erlang, "logger", "log")
fn logger_log_report(
  a: Level,
  b: Dict(Atom, Dynamic),
  c: Dict(Atom, Dynamic),
) -> Nil

@external(erlang, "logger", "log")
fn logger_log_message(a: Level, b: String, c: Dict(Atom, Dynamic)) -> Nil
