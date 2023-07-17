import gleam/list.{append, map}
import gleam/option.{Some}
import gleam/dynamic.{Dynamic}
import gleam/json.{int, object, string}
import glimt/erlang_logger/log_event.{Message, Report, decode_log_event}
import glimt/erlang_logger/common.{
  a, built_in_format, format_dynamic, set_handler_config, time_to_string,
}

/// Set `json_formatter` for erlang logger [handler](https://www.erlang.org/doc/apps/kernel/logger_chapter.html#handlers)
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
    #(a("glimt@erlang_logger@json_formatter"), dynamic.from(Nil)),
  )
}

/// This is the callback that will be used by erlang logger to format
/// log events. It is not intended to use directly.
pub fn format(log_event: Dynamic, config: Dynamic) {
  case decode_log_event(log_event) {
    Ok(log_event) -> {
      let common_json_fields = [
        #("time", int(log_event.time_us)),
        #("time_string", string(time_to_string(log_event.time_us))),
      ]
      let specific_json_fields = case log_event {
        Message(message: message, ..) -> [#("message", string(message))]
        Report(report: report, ..) ->
          report
          |> map(fn(entry) {
            let assert #(key, value) = entry
            #(format_dynamic(key), string(format_dynamic(value)))
          })
      }
      let report_json_fields = append(common_json_fields, specific_json_fields)
      let json_fields_with_error = case log_event.error {
        Some(error) -> [#("error", string(error)), ..report_json_fields]
        _ -> report_json_fields
      }
      object(json_fields_with_error)
      |> json.to_string() <> "\n"
    }
    _ -> {
      built_in_format(log_event, config)
    }
  }
}
