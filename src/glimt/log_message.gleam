import gleam/option.{Option}
import gleam/erlang/process.{Pid}

pub type LogMessage(data, result_type) {
  LogMessage(
    time: String,
    name: Option(String),
    pid: Pid,
    instance_name: Option(String),
    instance_pid: Option(Pid),
    level: LogLevel,
    level_value: Int,
    message: String,
    error: Option(Result(result_type, result_type)),
    data: Option(data),
  )
}

pub type LogLevel {
  ALL
  TRACE
  DEBUG
  INFO
  WARNING
  ERROR
  FATAL
  NONE
}

pub fn level_string(log_level: LogLevel) {
  case log_level {
    ALL -> "ALL"
    TRACE -> "TRACE"
    DEBUG -> "DEBUG"
    INFO -> "INFO"
    WARNING -> "WARNING"
    ERROR -> "ERROR"
    FATAL -> "FATAL"
    NONE -> "NONE"
  }
}

pub fn level_value(log_level: LogLevel) {
  case log_level {
    ALL -> 0
    TRACE -> 10
    DEBUG -> 20
    INFO -> 30
    WARNING -> 40
    ERROR -> 50
    FATAL -> 60
    NONE -> 1000
  }
}
