import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import gleam/erlang/process
import gleam/json as gjson
import glimt.{
  Actor, Direct, Logger, anonymous_stdout, append_instance, debug, error, fatal,
  info, level, log_with_data, new, new_stdout, start_instance,
  stdout_anonymous_instance, stdout_instance, trace, warning,
}
import glimt/log_message.{ALL, INFO, TRACE, level_value}
import glimt/serializer/basic.{basic_serializer}
import glimt/serializer/json.{json_serializer, json_serializer_with_data}
import glimt/dispatcher/stdout.{dispatcher}

pub fn main() {
  // gleeunit.main()
  // hello_world_test()
  examples()
}

type Data {
  Data(user_id: String, trace_id: String)
}

fn examples() {
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

  assert Ok(actor_instance) =
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
      dispatcher(json_serializer),
    ))
  json_logger
  |> info("Hi Hypsipyle, it's me Jason")

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
      dispatcher(json_serializer_with_data(_, data_serializer)),
    ))
  data_logger
  |> log_with_data(
    TRACE,
    "Fetching user achievements",
    Data("JohnBjrk", "322f38e8-d0a5-43f2-9590-6f435a9b5e41"),
  )

  process.sleep(200)
}

pub fn hello_world_test() {
  let root_logger = anonymous_stdout()
  root_logger
  |> info("This is a message from root_logger")
  let apa_logger =
    new_stdout("apa")
    |> level(TRACE)
    |> append_instance(Direct(
      None,
      level_value(TRACE),
      dispatcher(json_serializer),
    ))
  apa_logger
  |> trace("Trace message")
  apa_logger
  |> debug("Debug message")
  apa_logger
  |> info("Info message")
  apa_logger
  |> warning("Warning message")
  apa_logger
  |> error("Error message", Error(apa_logger))
  apa_logger
  |> fatal("Fatal message", Error(["Some", "Custom", "Error"]))

  assert Ok(actor_instance) =
    start_instance("actor", TRACE, dispatcher(basic_serializer))

  let actor_logger =
    new("multi")
    |> level(TRACE)
    |> append_instance(stdout_instance("direct", TRACE))
    |> append_instance(actor_instance)

  actor_logger
  |> info("Message from actor logger")

  let json_logger =
    new("json_logger")
    |> level(TRACE)
    |> append_instance(Direct(
      None,
      level_value(TRACE),
      dispatcher(json_serializer),
    ))
  json_logger
  |> info("Message from json logger")

  process.sleep(200)
}
