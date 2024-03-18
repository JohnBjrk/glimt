import gleam/io
import glimt/serializer.{type Serializer}

/// Dispatcher that writes the log message to stdout
pub fn dispatcher(serializer: Serializer(data, context, result_type)) {
  fn(log_message) { io.println(serializer(log_message)) }
}
