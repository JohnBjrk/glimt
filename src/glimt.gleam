import gleam/option.{None, Option, Some}
import gleam/dynamic.{Dynamic, from}
import gleam/erlang/process.{Subject, self}
import gleam/otp/actor
import gleam/list.{each}
import birl/datetime.{now, to_iso}
import glimt/log_message.{
  ALL, DEBUG, ERROR, FATAL, INFO, InstanceData, LogLevel, LogMessage, TRACE,
  WARNING, level_value,
}
import glimt/serializer/basic.{basic_serializer}
import glimt/dispatcher/stdout.{dispatcher}

pub opaque type Logger(data) {
  Logger(
    name: Option(String),
    level_min_value: Int,
    now: fn() -> String,
    instances: List(LoggerInstance(data)),
  )
}

pub type Dispatcher(data, result_type) =
  fn(LogMessage(data, result_type)) -> Nil

pub type LoggerInstance(data) {
  Direct(
    name: Option(String),
    level_min_value: Int,
    dispatch: Dispatcher(data, Dynamic),
  )
  Actor(
    name: Option(String),
    level_min_value: Int,
    Subject(LogMessage(data, Dynamic)),
  )
}

pub fn anonymous() {
  Logger(None, level_value(ALL), now_iso, [])
}

pub fn new(name: String) {
  Logger(Some(name), level_value(ALL), now_iso, [])
}

pub fn level(logger: Logger(data), level: LogLevel) {
  Logger(..logger, level_min_value: level_value(level))
}

pub fn new_direct_stdout(name: String, level: LogLevel) {
  Direct(Some(name), level_value(level), dispatcher(basic_serializer))
}

pub fn new_direct_stdout_anonymous(level: LogLevel) {
  Direct(None, level_value(level), dispatcher(basic_serializer))
}

pub fn anonymous_direct_logger() {
  anonymous()
  |> append_instance(new_direct_stdout_anonymous(ALL))
}

pub fn named_direct_logger(name: String) {
  new(name)
  |> append_instance(new_direct_stdout_anonymous(ALL))
}

pub fn append_instance(logger: Logger(data), instance: LoggerInstance(data)) {
  Logger(..logger, instances: [instance, ..logger.instances])
}

pub fn start_logger(
  dispatch,
) -> Result(Subject(LogMessage(data, Dynamic)), actor.StartError) {
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

pub fn debug(logger: Logger(Nil), message) {
  let log_message = mk_message(logger, DEBUG, message)
  dispatch_log(logger, log_message)
}

pub fn info(logger: Logger(Nil), message) {
  let log_message = mk_message(logger, INFO, message)
  dispatch_log(logger, log_message)
}

pub fn warning(logger: Logger(Nil), message) {
  let log_message = mk_message(logger, WARNING, message)
  dispatch_log(logger, log_message)
}

pub fn trace(logger: Logger(Nil), message) {
  let log_message = mk_message(logger, TRACE, message)
  dispatch_log(logger, log_message)
}

pub fn error(logger: Logger(Nil), message, error: Result(ok, err)) {
  let log_message = mk_error_message(logger, ERROR, message, error)
  dispatch_log(logger, log_message)
}

pub fn fatal(logger: Logger(Nil), message, error: Result(ok, err)) {
  let log_message = mk_error_message(logger, FATAL, message, error)
  dispatch_log(logger, log_message)
}

pub fn log(logger: Logger(Nil), level: LogLevel, message) {
  let log_message = mk_message(logger, level, message)
  dispatch_log(logger, log_message)
}

pub fn log_with_data(
  logger: Logger(data),
  level: LogLevel,
  message: String,
  data: data,
) {
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
      data: data,
    ),
  )
}

pub fn mk_message(logger: Logger(Nil), level: LogLevel, message: String) {
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
    data: Nil,
  )
}

pub fn mk_error_message(
  logger: Logger(Nil),
  level: LogLevel,
  message: String,
  error: Result(ok, err),
) {
  assert Error(error_content) = error
  LogMessage(
    time: logger.now(),
    name: logger.name,
    pid: self(),
    instance_name: None,
    instance_pid: None,
    level: level,
    level_value: level_value(level),
    message: message,
    error: Some(Error(from(error_content))),
    data: Nil,
  )
}

fn dispatch_log(logger: Logger(data), log_message: LogMessage(data, Dynamic)) {
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
