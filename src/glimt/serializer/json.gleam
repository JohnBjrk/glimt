import gleam/dynamic.{Dynamic}
import gleam/option.{None, Some}
import gleam/erlang.{format}
import gleam/string as str
import gleam/json.{Json, nullable, object, string}
import glimt/log_message.{LogMessage, level_string}

pub fn json_serializer(log_message: LogMessage(data, Dynamic)) -> String {
  object(to_json(log_message))
  |> json.to_string()
}

pub fn to_json(log_message: LogMessage(data, Dynamic)) -> List(#(String, Json)) {
  [
    #("time", string(log_message.time)),
    #("name", nullable(log_message.name, fn(name) { string(name) })),
    #("pid", string(format(log_message.pid))),
    #(
      "instance_name",
      nullable(
        log_message.instance_name,
        fn(instance_name) { string(instance_name) },
      ),
    ),
    #(
      "instance_pid",
      nullable(
        log_message.instance_pid,
        fn(instance_pid) { string(format(instance_pid)) },
      ),
    ),
    #("level", string(level_string(log_message.level))),
    #("message", string(log_message.message)),
    #(
      "error",
      nullable(log_message.error, fn(error) { string(str.inspect(error)) }),
    ),
  ]
}

pub fn json_serializer_with_data(
  log_message: LogMessage(data, Dynamic),
  data_serializer,
) -> String {
  let json_spec = to_json(log_message)
  case log_message.data {
    Some(data) -> object([#("data", data_serializer(data)), ..json_spec])
    None -> object(json_spec)
  }
  |> json.to_string()
}
