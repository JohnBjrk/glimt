import glimt/log_message.{LogMessage}

pub type Serializer(data, context, result_type) =
  fn(LogMessage(data, context, result_type)) -> String
