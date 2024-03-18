import gleam/result
import glimt/erlang_logger/level.{type Level}
import glimt/erlang_logger/common.{a}
import gleam/option.{type Option, None, Some}
import gleam/dict
import gleam/dynamic.{
  type DecodeError, type Dynamic, dynamic, element, field, int, string,
  unsafe_coerce,
}
import gleam/erlang/process.{type Pid}
import gleam/erlang/atom

/// Gleam representation of an erlang log event
pub type LogEvent {
  Message(
    time_us: Int,
    level: Level,
    message: String,
    pid: Pid,
    logger_name: Option(String),
    error: Option(String),
  )
  Report(
    time_us: Int,
    level: Level,
    report: List(#(Dynamic, Dynamic)),
    pid: Pid,
    logger_name: Option(String),
    error: Option(String),
  )
}

/// Translate a log event from erlang logger to corresponding gleam representation
/// This function is useful when implementing custom formatters for the erlang logger
pub fn decode_log_event(
  log_event: Dynamic,
) -> Result(LogEvent, List(DecodeError)) {
  use meta <- result.then(field(a("meta"), dynamic)(log_event))
  use time <- result.then(field(a("time"), int)(meta))
  use pid <- result.then(field(a("pid"), dynamic)(meta))
  let logger_name = case field(a("loggername"), string)(meta) {
    Ok(name) -> Some(name)
    _ -> None
  }
  let error = case field(a("error"), string)(meta) {
    Ok(error) -> Some(error)
    _ -> None
  }
  use level <- result.then(field(a("level"), dynamic)(log_event))
  use msg <- result.then(field(a("msg"), dynamic)(log_event))
  use msg_type <- result.then(element(0, dynamic)(msg))
  use msg_type_atom <- result.then(atom.from_dynamic(msg_type))
  case atom.to_string(msg_type_atom) {
    "string" -> {
      use message <- result.then(element(1, string)(msg))
      Ok(Message(
        time,
        unsafe_coerce(level),
        message,
        unsafe_coerce(pid),
        logger_name,
        error,
      ))
    }

    "report" -> {
      use report <- result.then(element(1, dynamic)(msg))
      Ok(Report(
        time,
        unsafe_coerce(level),
        report_as_list(report),
        unsafe_coerce(pid),
        logger_name,
        error,
      ))
    }
    _ -> panic as "Unexpected message type"
  }
}

fn report_as_list(report: Dynamic) {
  let list_result = dynamic.list(dynamic.tuple2(dynamic, dynamic))(report)
  case list_result {
    Ok(list) -> list
    _ -> {
      let map_result = dynamic.dict(dynamic, dynamic)(report)
      case map_result {
        Ok(map_report) -> dict.to_list(map_report)
        _ -> []
      }
    }
  }
}
