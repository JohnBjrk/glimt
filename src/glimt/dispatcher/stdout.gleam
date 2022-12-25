import gleam/io
import glimt/serializer.{Serializer}

pub fn dispatcher(serializer: Serializer(data, result_type)) {
  fn(log_message) { io.println(serializer(log_message)) }
}
