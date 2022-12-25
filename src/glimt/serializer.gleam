import glimt/log_message.{LogMessage}

pub type Serializer(data, result_type) =
  fn(LogMessage(data, result_type)) -> String
