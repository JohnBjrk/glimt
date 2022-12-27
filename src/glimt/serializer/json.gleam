import gleam/dynamic.{Dynamic}
import gleam/option.{None, Some}
import gleam/erlang.{format}
import gleam/list
import gleam/string as str
import gleam/json.{Json, nullable, object, string}
import glimt/log_message.{LogMessage, level_string}

pub fn new_json_serializer() {
  builder()
  |> add_standard_log_message()
  |> build()
}

pub fn builder() {
  fn(_log_message: LogMessage(data, context, Dynamic)) -> List(#(String, Json)) {
    []
  }
}

pub fn add_standard_log_message(builder) {
  fn(log_message: LogMessage(data, context, Dynamic)) -> List(#(String, Json)) {
    let standard_spec = [
      #("time", string(log_message.time)),
      #("name", string(log_message.name)),
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

    let previous_spec = builder(log_message)
    list.append(previous_spec, standard_spec)
  }
}

pub fn add_data(builder, data_serializer) {
  fn(log_message: LogMessage(data, context, Dynamic)) -> List(#(String, Json)) {
    let previous_spec = builder(log_message)
    let data_spec = case log_message.data {
      Some(data) -> [#("data", data_serializer(data))]
      None -> []
    }
    list.append(previous_spec, data_spec)
  }
}

pub fn add_context(builder, context_serializer) {
  fn(log_message: LogMessage(data, context, Dynamic)) -> List(#(String, Json)) {
    let previous_spec = builder(log_message)
    let context_spec = case log_message.context {
      Some(context) -> [#("context", context_serializer(context))]
      None -> []
    }
    list.append(previous_spec, context_spec)
  }
}

pub fn build(builder) {
  fn(log_message: LogMessage(data, context, Dynamic)) -> String {
    object(builder(log_message))
    |> json.to_string()
  }
}
