import gleam/io
import gleam/list
import gleam/string.{join} as gleam_string
import gleam/dynamic.{Dynamic, from}
import gleam/option.{None, Option, Some}
import gleam/erlang
import gleam/erlang/process.{Pid}
import glimt/erlang_logger/common.{
  a, built_in_format, format_dynamic, set_handler_config,
}
import glimt/erlang_logger/level.{
  Alert, Critical, Debug, Emergency, Error, Info, Level, Notice, Warning,
}
import glimt/erlang_logger/log_event.{Message, Report, decode_log_event}
import glimt/style.{
  style_debug, style_error, style_fatal, style_info, style_name, style_time,
  style_trace, style_warning,
}

pub fn use_with_handler(handler_id: String) {
  set_handler_config(
    a(handler_id),
    a("formatter"),
    #(a("glimt@erlang_logger@basic_formatter"), dynamic.from(Nil)),
  )
}

pub fn format(log_event: Dynamic, config: Dynamic) {
  case decode_log_event(log_event) {
    Ok(log_event) -> {
      let styled_time = style_time(time_to_string(log_event.time_us))
      let level_string = erlang.format(log_event.level)
      let styled_level = style_level(log_event.level)(level_string)
      let styled_name =
        style_name(format_name_and_pid(log_event.logger_name, log_event.pid))
      case log_event {
        Message(message: message, ..) -> {
          let styled_message = message
          styled_time <> " | " <> styled_level <> " | " <> styled_name <> " | " <> styled_message <> "\n"
        }
        Report(report: report, ..) -> {
          let styled_message = format_report(report)
          styled_time <> " | " <> styled_level <> " | " <> styled_name <> " | " <> styled_message <> "\n"
        }
      }
    }
    _ -> {
      io.println("Using build in format")
      built_in_format(log_event, config)
    }
  }
}

fn format_report(report: List(#(Dynamic, Dynamic))) {
  let report_content =
    report
    |> list.map(fn(entry) {
      assert #(key, value) = entry
      format_dynamic(key) <> " => " <> format_dynamic(value)
    })
    |> join(", ")
  "(" <> report_content <> ")"
}

fn format_name_and_pid(logger_name: Option(String), pid: Pid) {
  case logger_name {
    Some(name) -> name <> "(" <> erlang.format(pid) <> ")"
    None -> erlang.format(pid)
  }
}

pub fn style_level(log_level: Level) {
  case log_level {
    Emergency -> style_fatal()
    Alert -> style_fatal()
    Critical -> style_fatal()
    Error -> style_error()
    Warning -> style_warning()
    Notice -> style_info()
    Info -> style_debug()
    Debug -> style_trace()
  }
}

fn time_to_string(time: Int) -> String {
  system_time_to_rfc3339(time, from([#(a("unit"), a("microsecond"))]))
}

external fn system_time_to_rfc3339(time: Int, options: Dynamic) -> String =
  "calendar" "system_time_to_rfc3339"
