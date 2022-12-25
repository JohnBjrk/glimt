import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import gleam/erlang/process
import glimt.{
  Actor, Direct, Logger, anonymous_direct_logger, append_instance, debug, error,
  fatal, info, level, named_direct_logger, new, start_logger, trace, warning,
}
import glimt/log_message.{TRACE, level_value}
import glimt/serializer/basic.{basic_serializer}
import glimt/serializer/json.{json_serializer}
import glimt/dispatcher/stdout.{dispatcher}

pub fn main() {
  // gleeunit.main()
  hello_world_test()
}

pub fn hello_world_test() {
  let root_logger = anonymous_direct_logger()
  root_logger
  |> info("This is a message from root_logger")
  let apa_logger =
    named_direct_logger("apa")
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

  assert Ok(actor_logger_impl) = start_logger(dispatcher(basic_serializer))

  let actor_logger =
    new("multi")
    |> level(TRACE)
    |> append_instance(Direct(
      Some("direct"),
      level_value(TRACE),
      dispatcher(basic_serializer),
    ))
    |> append_instance(Actor(
      Some("actor"),
      level_value(TRACE),
      actor_logger_impl,
    ))

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
