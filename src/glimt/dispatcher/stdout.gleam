import gleam/io
import glimt/serializer.{Serializer}

pub fn dispatcher(serializer: Serializer(data, context, result_type)) {
  fn(log_message) { io.println(serializer(log_message)) }
}
