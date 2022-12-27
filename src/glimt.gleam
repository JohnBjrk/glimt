import gleam/option.{None, Option, Some}
import gleam/result
import gleam/dynamic.{Dynamic, from}
import gleam/erlang/process.{Subject, self}
import gleam/otp/actor
import gleam/list.{each}
import birl/datetime.{now, to_iso}
import glimt/log_message.{
  ALL, DEBUG, ERROR, FATAL, INFO, LogLevel, LogMessage, TRACE, WARNING,
  level_value,
}
import glimt/serializer/basic.{basic_serializer}
import glimt/dispatcher/stdout.{dispatcher}

/// Logger that can be use for logging of a `LogMessage` with possible additional `data`
/// to one or more `LoggerInstance`
pub opaque type Logger(data, context) {
  Logger(
    name: Option(String),
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
pub fn anonymous() -> Logger(data, context) {
  Logger(
    name: None,
    level_min_value: level_value(ALL),
    now: now_iso,
    context: None,
    instances: [],
  )
}

pub fn new(name: String) -> Logger(data, context) {
  Logger(
    name: Some(name),
    level_min_value: level_value(ALL),
    now: now_iso,
    context: None,
    instances: [],
  )
}

pub fn level(
  logger: Logger(data, context),
  level: LogLevel,
) -> Logger(data, context) {
  Logger(..logger, level_min_value: level_value(level))
}

pub fn add_context(logger: Logger(data, context), context: context) {
  Logger(..logger, context: Some(context))
}

pub fn get_context(logger: Logger(data, context)) -> Option(context) {
  logger.context
}

pub fn anonymous_stdout() -> Logger(Nil, #(String, String)) {
  anonymous()
  |> append_instance(stdout_anonymous_instance(ALL))
}

pub fn new_stdout(name: String) -> Logger(Nil, #(String, String)) {
  new(name)
  |> append_instance(stdout_anonymous_instance(ALL))
}

pub fn append_instance(
  logger: Logger(data, context),
  instance: LoggerInstance(data, context),
) -> Logger(data, context) {
  Logger(..logger, instances: [instance, ..logger.instances])
}

pub fn stdout_instance(
  name: String,
  level: LogLevel,
) -> LoggerInstance(data, context) {
  Direct(Some(name), level_value(level), dispatcher(basic_serializer))
}

pub fn stdout_anonymous_instance(
  level: LogLevel,
) -> LoggerInstance(data, context) {
  Direct(None, level_value(level), dispatcher(basic_serializer))
}

pub fn start_instance(
  name: String,
  level: LogLevel,
  dispatch: Dispatcher(data, context, result_type),
) -> Result(LoggerInstance(data, context), actor.StartError) {
  start_logger_actor(dispatch)
  |> result.map(fn(subject) { Actor(Some(name), level_value(level), subject) })
}

pub fn start_logger_actor(
  dispatch,
) -> Result(Subject(LogMessage(data, context, Dynamic)), actor.StartError) {
  actor.start(
    dispatch,
    fn(message, dispatch) {
      case message {
        LogMessage(..) ->
          dispatch(LogMessage(..message, instance_pid: Some(self())))
        _ -> Nil
      }
      actor.Continue(dispatch)
    },
  )
}

pub fn debug(
  logger: Logger(data, context),
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, DEBUG, message)
  dispatch_log(logger, log_message)
  logger
}

pub fn info(
  logger: Logger(data, context),
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, INFO, message)
  dispatch_log(logger, log_message)
  logger
}

pub fn warning(
  logger: Logger(data, context),
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, WARNING, message)
  dispatch_log(logger, log_message)
  logger
}

pub fn trace(
  logger: Logger(data, context),
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, TRACE, message)
  dispatch_log(logger, log_message)
  logger
}

pub fn error(
  logger: Logger(data, context),
  message: String,
  error: Result(ok, err),
) -> Logger(data, context) {
  let log_message = mk_error_message(logger, ERROR, message, error)
  dispatch_log(logger, log_message)
  logger
}

pub fn fatal(
  logger: Logger(data, context),
  message: String,
  error: Result(ok, err),
) -> Logger(data, context) {
  let log_message = mk_error_message(logger, FATAL, message, error)
  dispatch_log(logger, log_message)
  logger
}

pub fn log(
  logger: Logger(data, context),
  level: LogLevel,
  message: String,
) -> Logger(data, context) {
  let log_message = mk_message(logger, level, message)
  dispatch_log(logger, log_message)
  logger
}

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
          Direct(instance_name, level_min_value, dispatch) if level_value >= level_min_value ->
            dispatch(LogMessage(..log_message, instance_name: instance_name))
          Actor(instance_name, level_min_value, subject) if level_value >= level_min_value ->
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
  |> to_iso()
}
