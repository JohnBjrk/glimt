import gleam/io
import gleam/list
import gleam/string.{join} as gleam_string
import gleam/dynamic.{Dynamic}
import gleam/option.{None, Option, Some}
import gleam/erlang
import gleam/erlang/process.{Pid}
import glimt/erlang_logger/common.{
  a, built_in_format, format_dynamic, set_handler_config, time_to_string,
}
import glimt/erlang_logger/log_event.{Message, Report, decode_log_event}
import glimt/style.{style_erlang_level, style_name, style_time}

/// Set `basic_formatter` for erlang logger [handler](https://www.erlang.org/doc/apps/kernel/logger_chapter.html#handlers)
/// with `handler_id`
///
/// Example:
/// ```gleam
/// use_with_handler("default")
/// ```
///
/// Set basic Glimt formatting for the default handler (logger_std_h)
pub fn use_with_handler(handler_id: String) {
  set_handler_config(
    a(handler_id),
    a("formatter"),
    #(a("glimt@erlang_logger@basic_formatter"), dynamic.from(Nil)),
  )
}

/// This is the callback that will be used by erlang logger to format
/// log events. It is not intended to use directly.
pub fn format(log_event: Dynamic, config: Dynamic) {
  case decode_log_event(log_event) {
    Ok(log_event) -> {
      let styled_time = style_time(time_to_string(log_event.time_us))
      let styled_level =
        erlang.format(log_event.level)
        |> style_erlang_level(log_event.level)
      let styled_name =
        style_name(format_name_and_pid(log_event.logger_name, log_event.pid))
      let error_string = case log_event.error {
        Some(error) -> " | " <> error
        None -> ""
      }
      case log_event {
        Message(message: message, ..) -> {
          let styled_message = message
          styled_time <> " | " <> styled_level <> " | " <> styled_name <> " | " <> styled_message <> error_string <> "\n"
        }
        Report(report: report, ..) -> {
          let styled_message = format_report(report)
          styled_time <> " | " <> styled_level <> " | " <> styled_name <> " | " <> styled_message <> error_string <> "\n"
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
      let assert #(key, value) = entry
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
