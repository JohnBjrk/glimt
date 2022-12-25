import gleam/dynamic.{Dynamic}
import gleam/erlang.{format}
import gleam/string as str
import gleam/json.{nullable, object, string}
import glimt/log_message.{LogMessage, level_string}

pub fn json_serializer(log_message: LogMessage(Nil, Dynamic)) -> String {
  object([
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
  ])
  |> json.to_string()
}
