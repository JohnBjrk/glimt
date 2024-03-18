import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/dynamic.{type Dynamic, from}
import gleam/erlang/process.{type Subject, self}
import gleam/otp/actor
import gleam/list.{each}
import birl.{now, to_iso8601}
import glimt/log_message.{
  type LogLevel, type LogMessage, ALL, DEBUG, ERROR, FATAL, INFO, LogMessage,
  TRACE, WARNING, level_value,
}
import glimt/serializer/basic.{basic_serializer}
import glimt/dispatcher/stdout.{dispatcher}

/// Logger that can be use for logging of a `LogMessage` with possible additional `data`
/// to one or more `LoggerInstance`
pub opaque type Logger(data, context) {
  Logger(
    name: String,
    level_min_value: Int,
    now: fn() -> String,
    context: Option(context),
    instances: List(LoggerInstance(data, context)),
  )
}

/// Generic `Dispatcher` the can dispatch a `LogMessage` with a given `data` type and 
/// errors of a given type (build in dispatchers use `Dynamic` as error type)
pub type Dispatcher(data, context, result_type) =
  fn(LogMessage(data, context, result_type)) -> Nil

/// A logger instance can be either `Direct` (logging in same process) or `Actor` (logging
/// in a separate process) 
pub type LoggerInstance(data, context) {
  Direct(
    name: Option(String),
    level_min_value: Int,
    dispatch: Dispatcher(data, context, Dynamic),
  )
  Actor(
    name: Option(String),
    level_min_value: Int,
    Subject(LogMessage(data, context, Dynamic)),
  )
}

/// Create a new logger with the name "anonymous" that accepts any `LogLevel`
/// The `Logger` starts without any [LoggerInstance](#LoggerInstance)
pub fn new(name: String) -> Logger(data, context) {
  Logger(
    name: name,
    level_min_value: level_value(ALL),
    now: now_iso,
    context: None,
    instances: [],
  )
}

/// Set a new minimum level for the logger
pub fn level(
  logger: Logger(data, context),
  level: LogLevel,
) -> Logger(data, context) {
  Logger(..logger, level_min_value: level_value(level))
}

/// Add context data to the logger
pub fn with_context(logger: Logger(data, context), context: context) {
  Logger(..logger, context: Some(context))
}

/// Get current context data for the logger
pub fn get_context(logger: Logger(data, context)) -> Option(context) {
  logger.context
}

/// Set the function used to get time. The function should return a string representation
/// of the current time. Can be used to configure the date/time format
pub fn with_time_provider(
  logger: Logger(data, context),
  time_provider: fn() -> String,
) {
  Logger(..logger, now: time_provider)
}

/// Convenience method for getting a direct stdout logger with basic serialization
/// that accepts all log levels
pub fn new_stdout(name: String) -> Logger(Nil, #(String, String)) {
  new(name)
  |> append_instance(stdout_anonymous_instance(ALL))
}

/// Add an instance to the logger
pub fn append_instance(
  logger: Logger(data, context),
  instance: LoggerInstance(data, context),
) -> Logger(data, context) {
  Logger(..logger, instances: [instance, ..logger.instances])
}

/// Creates a direct stdout instance with basic serialization
pub fn stdout_instance(
  name: String,
  level: LogLevel,
) -> LoggerInstance(data, context) {
  Direct(Some(name), level_value(level), dispatcher(basic_serializer))
}

/// Create an unnamed direct stdout instance with basic serialization
pub fn stdout_anonymous_instance(
  level: LogLevel,
) -> LoggerInstance(data, context) {
  Direct(None, level_value(level), dispatcher(basic_serializer))
}

/// Starts an actor instance that logs using the provided dispatcher and a
/// specified level
pub fn start_instance(
  name: String,
  level: LogLevel,
  dispatch: Dispatcher(data, context, Dynamic),
) -> Result(LoggerInstance(data, context), actor.StartError) {
  start_logger_actor(dispatch)
  |> result.map(fn(subject) { Actor(Some(name), level_value(level), subject) })
}

fn start_logger_actor(
  dispatch: Dispatcher(data, context, Dynamic),
) -> Result(Subject(LogMessage(data, context, Dynamic)), actor.StartError) {
  actor.start(dispatch, fn(message, dispatch) {
    case message {
      LogMessage(..) ->
        dispatch(LogMessage(..message, instance_pid: Some(self())))
    }
    actor.continue(dispatch)
  })
}

/// Log a message at `DEBUG` level
pub fn debug(
  logger: Logger(data, context),
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, DEBUG, message)
  dispatch_log(logger, log_message)
  logger
}

/// Log a message at `INFO` level
pub fn info(
  logger: Logger(data, context),
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, INFO, message)
  dispatch_log(logger, log_message)
  logger
}

/// Log a message at `WARNING` level
pub fn warning(
  logger: Logger(data, context),
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, WARNING, message)
  dispatch_log(logger, log_message)
  logger
}

/// Log a message at `TRACE` level
pub fn trace(
  logger: Logger(data, context),
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, TRACE, message)
  dispatch_log(logger, log_message)
  logger
}

/// Log a message at `ERROR` level with the provided `Result`
pub fn error(
  logger: Logger(data, context),
  message: String,
  error: Result(ok, err),
) -> Logger(data, context) {
  let log_message = mk_error_message(logger, ERROR, message, error)
  dispatch_log(logger, log_message)
  logger
}

/// Log a message at `FATAL` level with the provided `Result`
pub fn fatal(
  logger: Logger(data, context),
  message: String,
  error: Result(ok, err),
) -> Logger(data, context) {
  let log_message = mk_error_message(logger, FATAL, message, error)
  dispatch_log(logger, log_message)
  logger
}

/// Log a message at the provided level
pub fn log(
  logger: Logger(data, context),
  level: LogLevel,
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, level, message)
  dispatch_log(logger, log_message)
  logger
}

/// Log a message at the provided level with some additional data
pub fn log_with_data(
  logger: Logger(data, context),
  level: LogLevel,
  message: String,
  data: data,
) -> Logger(data, context) {
  dispatch_log(
    logger,
    LogMessage(
      time: logger.now(),
      name: logger.name,
      pid: self(),
      instance_name: None,
      instance_pid: None,
      level: level,
      level_value: level_value(level),
      message: message,
      error: None,
      data: Some(data),
      context: logger.context,
    ),
  )
  logger
}

/// Log a message at the provided level together with the provided `Result` and data
pub fn log_error_with_data(
  logger: Logger(data, context),
  level: LogLevel,
  message: String,
  error: Result(ok, err),
  data: data,
) -> Logger(data, context) {
  let dynamic_result = case error {
    Ok(a) -> Some(Ok(from(a)))
    Error(a) -> Some(Error(from(a)))
  }
  dispatch_log(
    logger,
    LogMessage(
      time: logger.now(),
      name: logger.name,
      pid: self(),
      instance_name: None,
      instance_pid: None,
      level: level,
      level_value: level_value(level),
      message: message,
      error: dynamic_result,
      data: Some(data),
      context: logger.context,
    ),
  )
  logger
}

fn mk_message(
  logger: Logger(data, context),
  level: LogLevel,
  message: String,
) -> LogMessage(data, context, Dynamic) {
  LogMessage(
    time: logger.now(),
    name: logger.name,
    pid: self(),
    instance_name: None,
    instance_pid: None,
    level: level,
    level_value: level_value(level),
    message: message,
    error: None,
    data: None,
    context: logger.context,
  )
}

fn mk_error_message(
  logger: Logger(data, context),
  level: LogLevel,
  message: String,
  error: Result(ok, err),
) -> LogMessage(data, context, Dynamic) {
  let dynamic_result = case error {
    Ok(a) -> Some(Ok(from(a)))
    Error(a) -> Some(Error(from(a)))
  }
  LogMessage(
    time: logger.now(),
    name: logger.name,
    pid: self(),
    instance_name: None,
    instance_pid: None,
    level: level,
    level_value: level_value(level),
    message: message,
    error: dynamic_result,
    data: None,
    context: logger.context,
  )
}

fn dispatch_log(
  logger: Logger(data, context),
  log_message: LogMessage(data, context, Dynamic),
) {
  let LogMessage(level_value: level_value, ..) = log_message
  logger.instances
  |> each(fn(impl) {
    case log_message.level_value >= logger.level_min_value {
      True ->
        case impl {
          Direct(instance_name, level_min_value, dispatch)
            if level_value >= level_min_value
          -> dispatch(LogMessage(..log_message, instance_name: instance_name))
          Actor(instance_name, level_min_value, subject) if level_value
            >= level_min_value ->
            subject
            |> process.send(
              LogMessage(..log_message, instance_name: instance_name),
            )
          _ -> Nil
        }
      _ -> Nil
    }
  })
}

fn now_iso() -> String {
  now()
  |> to_iso8601()
}
