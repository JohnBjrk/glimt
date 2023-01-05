import glimt/erlang_logger/level.{Level}
import glimt/erlang_logger/common.{a}
import gleam/option.{None, Option, Some}
import gleam/map
import gleam/dynamic.{
  DecodeError, Dynamic, dynamic, element, field, int, string, unsafe_coerce,
}
import gleam/erlang/process.{Pid}
import gleam/erlang/atom

pub type LogEvent {
  Message(
    time_us: Int,
    level: Level,
    message: String,
    pid: Pid,
    logger_name: Option(String),
  )
  Report(
    time_us: Int,
    level: Level,
    report: List(#(Dynamic, Dynamic)),
    pid: Pid,
    logger_name: Option(String),
  )
}

pub fn decode_log_event(
  log_event: Dynamic,
) -> Result(LogEvent, List(DecodeError)) {
  try meta = field(a("meta"), dynamic)(log_event)
  try time = field(a("time"), int)(meta)
  try pid = field(a("pid"), dynamic)(meta)
  let logger_name = case field(a("loggername"), string)(meta) {
    Ok(name) -> Some(name)
    _ -> None
  }
  try level = field(a("level"), dynamic)(log_event)
  try msg = field(a("msg"), dynamic)(log_event)
  try msg_type = element(0, dynamic)(msg)
  try msg_type_atom = atom.from_dynamic(msg_type)
  case atom.to_string(msg_type_atom) {
    "string" -> {
      try message = element(1, string)(msg)
      Ok(Message(
        time,
        unsafe_coerce(level),
        message,
        unsafe_coerce(pid),
        logger_name,
      ))
    }

    "report" -> {
      try report = element(1, dynamic)(msg)
      Ok(Report(
        time,
        unsafe_coerce(level),
        report_as_list(report),
        unsafe_coerce(pid),
        logger_name,
      ))
    }
  }
}

fn report_as_list(report: Dynamic) {
  let list_result = dynamic.list(dynamic.tuple2(dynamic, dynamic))(report)
  case list_result {
    Ok(list) -> list
    _ -> {
      let map_result = dynamic.map(dynamic, dynamic)(report)
      case map_result {
        Ok(map_report) -> map.to_list(map_report)
        _ -> []
      }
    }
  }
}
