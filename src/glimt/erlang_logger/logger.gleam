import gleam/dynamic.{Dynamic, from}
import gleam/list.{append, map}
import gleam/map.{Map}
import gleam/string.{inspect}
import gleam/option.{Option, Some}
import glimt/log_message.{
  ALL, DEBUG, ERROR, FATAL, INFO, LogLevel, LogMessage, NONE, TRACE, WARNING,
}
import glimt/erlang_logger/level.{Critical, Debug, Info, Level, Notice, Warning}
import glimt/erlang_logger/common.{a}
import gleam/erlang/atom.{Atom}

pub fn logger_dispatch(log_message: LogMessage(data, context, Dynamic)) {
  logger_log_message(
    map_level(log_message.level),
    log_message.message,
    create_meta(log_message),
  )
}

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
    map.from_list(report),
    create_meta(log_message),
  )
}

fn create_meta(log_message: LogMessage(data, context, Dynamic)) {
  let meta_with_name = [#(a("loggername"), from(log_message.name))]
  let meta = case log_message.error {
    Some(error) -> [#(a("error"), from(inspect(error))), ..meta_with_name]
    _ -> meta_with_name
  }
  map.from_list(meta)
}

fn as_report_list(data: Option(List(#(String, String)))) {
  case data {
    Some(data) ->
      data
      |> map(fn(entry) {
        assert #(key, value) = entry
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

pub external fn logger_log_report(
  Level,
  Map(Atom, Dynamic),
  Map(Atom, Dynamic),
) -> Nil =
  "logger" "log"

external fn logger_log_message(Level, String, Map(Atom, Dynamic)) -> Nil =
  "logger" "log"
