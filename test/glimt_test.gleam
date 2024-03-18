import showtime
import showtime/tests/should
// import glimt.{
//   Direct, append_instance, debug, error, fatal, info, level, log_with_data, new,
//   new_stdout, start_instance, trace, warning, with_context, with_time_provider,
// }
// import glimt/log_message.{ALL, INFO, TRACE, level_value}
// import glimt/serializer/basic.{basic_serializer}
// import glimt/serializer/json.{
//   add_context, add_data, add_standard_log_message, build, builder,
//   new_json_serializer,
// }
// import glimt/dispatcher/stdout.{dispatcher}
import glimt/erlang_logger/common.{a}
import glimt/erlang_logger/level.{Notice}
// import glimt/erlang_logger/logger.{logger_dispatch, logger_report_dispatch}
import glimt/erlang_logger/basic_formatter
// import glimt/erlang_logger/json_formatter
// import gleam/io
import gleam/dict
import gleam/string
import gleam/dynamic
import gleam/erlang/charlist.{type Charlist}
import demo.{examples}

pub fn main() {
  showtime.main()
}

pub fn examples_test() {
  examples()
}

pub fn basic_formatter_minimal_test() {
  basic_formatter.format(
    dynamic.from(
      dict.from_list([
        #(a("level"), dynamic.from(Notice)),
        #(a("msg"), dynamic.from(#(a("string"), "Test"))),
        #(a("meta"), dynamic.from(dict.from_list([]))),
      ]),
    ),
    dynamic.from(dict.new()),
  )
  |> string.trim()
  |> should.equal("notice: Test")
}

pub fn basic_formatter_unsupported_msg_type_test() {
  basic_formatter.format(
    dynamic.from(
      dict.from_list([
        #(a("level"), dynamic.from(Notice)),
        #(a("msg"), dynamic.from(#("Test ~s ~s", ["some", "terms"]))),
        #(a("meta"), dynamic.from(dict.from_list([]))),
      ]),
    ),
    dynamic.from(dict.new()),
  )
  |> string.trim()
  |> should.equal("notice: Test some terms")
}

const esc = "\u{001B}"

pub fn basic_formatter_list_report_test() {
  basic_formatter.format(
    dynamic.from(
      dict.from_list([
        #(a("level"), dynamic.from(Notice)),
        #(
          a("msg"),
          dynamic.from(
            #(a("report"), [#(a("field1"), "value1"), #(a("field2"), "value2")]),
          ),
        ),
        #(
          a("meta"),
          dynamic.from(
            dict.from_list([
              #(
                a("time"),
                dynamic.from(
                  time_ms_from_string(charlist.from_string(
                    "2023-01-06T17:14:42.640870+01:00",
                  )),
                ),
              ),
              #(a("pid"), dynamic.from("<0.93.0>")),
            ]),
          ),
        ),
      ]),
    ),
    dynamic.from(dict.new()),
  )
  |> string.trim()
  |> should.equal(
    esc
    <> "[2m2023-01-06T16:14:42.640870+00:00"
    <> esc
    <> "[22m | "
    <> esc
    <> "[32mnotice"
    <> esc
    <> "[39m | "
    <> esc
    <> "[35m<<\"<0.93.0>\">>"
    <> esc
    <> "[39m | (field1 => value1, field2 => value2)",
  )
}

fn time_ms_from_string(date_time: Charlist) {
  rfc3339_to_system_time(date_time, [#(a("unit"), a("microsecond"))])
}

@external(erlang, "calendar", "rfc3339_to_system_time")
fn rfc3339_to_system_time(a: date_time, b: options) -> Int
