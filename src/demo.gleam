import gleam/option.{None}
import gleam/erlang/process
import gleam/json as gjson
import gleam/http.{method_to_string}
import gleam/http/request.{type Request, set_path}
import glimt.{
  Direct, append_instance, debug, error, fatal, info, level, log_with_data, new,
  new_stdout, start_instance, trace, warning, with_context, with_time_provider,
}
import glimt/log_message.{ALL, INFO, TRACE, level_value}
import glimt/serializer/basic.{basic_serializer}
import glimt/serializer/json.{
  add_context, add_data, add_standard_log_message, build, builder,
  new_json_serializer,
}
import glimt/dispatcher/stdout.{dispatcher}
import glimt/erlang_logger/logger.{logger_dispatch, logger_report_dispatch}
import glimt/erlang_logger/basic_formatter
import glimt/erlang_logger/json_formatter

type Data {
  Data(user_id: String, trace_id: String)
}

pub fn main() {
  examples()
}

pub fn examples() {
  new_stdout("now_logger")
  |> with_time_provider(fn() { "NOW" })
  |> info("No time as the present")

  let example_logger = new_stdout("example_logger")
  example_logger
  |> info("Entering hyperspace")

  let levels_logger = new_stdout("levels_logger")
  levels_logger
  |> trace("Hyperdrive subsystem A entering state PRE_ACTIVE")
  levels_logger
  |> debug("Hyperdrive subsystems states: A=PRE_ACTIVE, B=RUNNING")
  levels_logger
  |> info("Entering hyperspace")
  levels_logger
  |> warning("Hyperdrive subsystem A got unexpected command: Nil")
  levels_logger
  |> error(
    "Exiting hyperspace due to system failure",
    Error("Subsystem A quit unexpectedly"),
  )
  levels_logger
  |> fatal(
    "Could not reboot shields after exiting hyperspace",
    Error([
      "ENEMY SHIP DETECTED", "ACTIVATE_SHIELDS", "REBOOT_SHIELDS",
      "REBOOT_FAILURE",
    ]),
  )

  let custom_logger =
    new("custom_logger")
    |> level(ALL)
    |> append_instance(Direct(
      None,
      level_value(TRACE),
      dispatcher(basic_serializer),
    ))
  custom_logger
  |> info("Entering hyperspace")

  let message_logger =
    new("message_logger")
    |> level(ALL)
    |> append_instance(Direct(
      None,
      level_value(TRACE),
      dispatcher(fn(log_message) { log_message.message }),
    ))
  message_logger
  |> warning(
    "An important message to all our travelers. We are being attacked by enemy ships.",
  )

  let assert Ok(actor_instance) =
    start_instance("actor_instance", TRACE, dispatcher(basic_serializer))
  let actor_logger =
    new("actor_logger")
    |> level(INFO)
    |> append_instance(actor_instance)
  actor_logger
  |> trace("Cutting the blue wire")
  actor_logger
  |> info("Bomb disarmed 💣")

  let json_logger =
    new("json_logger")
    |> level(TRACE)
    |> append_instance(Direct(
      None,
      level_value(TRACE),
      dispatcher(new_json_serializer()),
    ))
  json_logger
  |> info("Hi Hypsipyle, it's me Thoas")

  let data_serializer = fn(data: Data) {
    gjson.object([
      #("user_id", gjson.string(data.user_id)),
      #("trace_id", gjson.string(data.trace_id)),
    ])
  }

  let data_logger =
    new("data_logger")
    |> level(TRACE)
    |> append_instance(Direct(
      None,
      level_value(TRACE),
      dispatcher(
        builder()
        |> add_standard_log_message()
        |> add_data(data_serializer)
        |> build(),
      ),
    ))
  data_logger
  |> log_with_data(
    TRACE,
    "Fetching user achievements",
    Data("JohnBjrk", "322f38e8-d0a5-43f2-9590-6f435a9b5e41"),
  )

  let request_serializer = fn(request: Request(content_type)) {
    gjson.object([
      #(
        "request",
        gjson.object([
          #("method", gjson.string(method_to_string(request.method))),
          #("path", gjson.string(request.path)),
        ]),
      ),
    ])
  }

  let context_logger =
    new("context_logger")
    |> level(TRACE)
    |> append_instance(Direct(
      None,
      level_value(TRACE),
      dispatcher(
        builder()
        |> add_standard_log_message()
        |> add_context(request_serializer)
        |> build(),
      ),
    ))

  let logger_with_request =
    context_logger
    |> with_context(
      request.new()
      |> set_path("api/login"),
    )

  logger_with_request
  |> info("User successfully logged in")

  let logger_logger =
    new("logger_logger")
    |> level(TRACE)
    |> append_instance(Direct(None, level_value(TRACE), logger_dispatch))

  basic_formatter.use_with_handler("default")
  logger_logger
  |> error(
    "Could not connect to database",
    Error("Connection timeout: 127:0.0.1:5432"),
  )

  let report_logger =
    new("report_logger")
    |> level(TRACE)
    |> append_instance(Direct(None, level_value(TRACE), logger_report_dispatch))

  report_logger
  |> with_context([
    #("host", "blue-panda.fly.dev"),
    #("url", "users"),
    #("params", "token=48dhf8h826ad876f78&"),
  ])
  |> log_with_data(INFO, "Successfully fetched user data", [
    #("username", "JohnBjrk"),
    #("github_url", "https://github.com/JohnBjrk"),
  ])

  let logger_logger =
    new("logger_logger")
    |> level(TRACE)
    |> append_instance(Direct(None, level_value(TRACE), logger_dispatch))

  json_formatter.use_with_handler("default")
  logger_logger
  |> error(
    "Could not connect to database",
    Error("Connection timeout: 127:0.0.1:5432"),
  )

  let report_logger =
    new("report_logger")
    |> level(TRACE)
    |> append_instance(Direct(None, level_value(TRACE), logger_report_dispatch))

  report_logger
  |> with_context([
    #("host", "blue-panda.fly.dev"),
    #("url", "users"),
    #("params", "token=48dhf8h826ad876f78&"),
  ])
  |> log_with_data(INFO, "Successfully fetched user data", [
    #("username", "JohnBjrk"),
    #("github_url", "https://github.com/JohnBjrk"),
  ])
  process.sleep(200)
}
