import gleam/dynamic.{Dynamic}
import gleam/map.{Map}
import glimt/log_message.{
  ALL, DEBUG, ERROR, FATAL, INFO, LogLevel, LogMessage, NONE, TRACE, WARNING,
}
import glimt/erlang_logger/level.{Critical, Debug, Info, Level, Notice, Warning}
import glimt/erlang_logger/common.{a}
import gleam/erlang/atom.{Atom}

pub fn logger_dispatch(log_message: LogMessage(data, context, result_type)) {
  logger_log_message(
    map_level(log_message.level),
    log_message.message,
    map.from_list([#(a("loggername"), log_message.name)]),
  )
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

pub external fn logger_log_report(Level, Map(Atom, Dynamic)) -> Nil =
  "logger" "log"

external fn logger_log_message(Level, String, Map(Atom, String)) -> Nil =
  "logger" "log"
