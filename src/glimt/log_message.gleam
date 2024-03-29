import gleam/option.{type Option}
import gleam/erlang/process.{type Pid}

/// LogMessage contains all the data that can be dispatched/serialized by a logger instance
pub type LogMessage(data, context, result_type) {
  LogMessage(
    time: String,
    name: String,
    pid: Pid,
    instance_name: Option(String),
    instance_pid: Option(Pid),
    level: LogLevel,
    level_value: Int,
    message: String,
    error: Option(Result(result_type, result_type)),
    data: Option(data),
    context: Option(context),
  )
}

/// LogLevel used in log messages and as limits for loggers
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

// Convert LogLevel to a string
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

// Convert LogLevel to a value. Higher level means more critical log message
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
