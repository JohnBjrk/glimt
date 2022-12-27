import gleam/dynamic.{Dynamic}
import gleam/option.{None, Some}
import gleam/erlang.{format}
import gleam/list
import gleam/string as str
import gleam/json.{Json, nullable, object, string}
import glimt/serializer.{Serializer}
import glimt/log_message.{LogMessage, level_string}

pub type JsonSerializerBuilder(data, context, result_type) =
  fn(LogMessage(data, context, result_type)) -> List(#(String, Json))

/// Creates a new JSON serializer that includes standard log data
pub fn new_json_serializer() {
  builder()
  |> add_standard_log_message()
  |> build()
}

/// Create a JSON serializer builder
pub fn builder() -> JsonSerializerBuilder(data, context, result_type) {
  fn(_log_message: LogMessage(data, context, result_type)) -> List(
    #(String, Json),
  ) {
    []
  }
}

/// Add standard log message to serializer
pub fn add_standard_log_message(
  builder: JsonSerializerBuilder(data, context, result_type),
) -> JsonSerializerBuilder(data, context, result_type) {
  fn(log_message: LogMessage(data, context, result_type)) -> List(
    #(String, Json),
  ) {
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

/// Add serializer for additional data
pub fn add_data(
  builder: JsonSerializerBuilder(data, context, result_type),
  data_serializer: fn(data) -> Json,
) -> JsonSerializerBuilder(data, context, result_type) {
  fn(log_message: LogMessage(data, context, result_type)) -> List(
    #(String, Json),
  ) {
    let previous_spec = builder(log_message)
    let data_spec = case log_message.data {
      Some(data) -> [#("data", data_serializer(data))]
      None -> []
    }
    list.append(previous_spec, data_spec)
  }
}

/// Add serializer for context data
pub fn add_context(
  builder: JsonSerializerBuilder(data, context, result_type),
  context_serializer: fn(context) -> Json,
) -> JsonSerializerBuilder(data, context, result_type) {
  fn(log_message: LogMessage(data, context, result_type)) -> List(
    #(String, Json),
  ) {
    let previous_spec = builder(log_message)
    let context_spec = case log_message.context {
      Some(context) -> [#("context", context_serializer(context))]
      None -> []
    }
    list.append(previous_spec, context_spec)
  }
}

/// Create a serializer from builder
pub fn build(
  builder: JsonSerializerBuilder(data, context, result_type),
) -> Serializer(data, context, result_type) {
  fn(log_message: LogMessage(data, context, result_type)) -> String {
    object(builder(log_message))
    |> json.to_string()
  }
}
