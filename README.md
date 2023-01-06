# glimt

[![Package Version](https://img.shields.io/hexpm/v/glimt)](https://hex.pm/packages/glimt)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/glimt/)

A Gleam library for logging


*Get a glimpse (glimt in Swedish) of what is going on inside your software*

## Installation

```sh
gleam add glimt
```

Documentation can be found at <https://hexdocs.pm/glimt>.

## Quick start

Glimt is a logging library for Gleam that aims to modular in terms of how log-messages are dispatched and serialize while providing some default implementations that can be used out-of-the-box.

A simple way to start logging is to use the built-in stdout logger.

```gleam
let example_logger = new_stdout("example_logger")
example_logger
|> info("Entering hyperspace")
```

This will produce a human readable log-line in your terminal that looks something like this:

> <span style="color:gray">2022-12-25T15:56:40.244Z</span> | <span style="color:green">INFO</span> | <span style="color:magenta">example_logger(<0.9.0>)</span> | Entering hyperspace

Of course you can log with different levels. The default stdout logger will print all levels as seen in the following example.

```gleam
let levels_logger = new_stdout("levels_logger")
levels_logger
|> trace("Hyperdrive subsystem A entering state PRE_ACTIVE")
levels_logger
|> debug("Hyperdrive subsystems states: A=PRE_ACTIVE, B=RUNNING")
levels_logger
|> info("Entering hyperspace")
levels_logger
|> warning("Hyperdrive subsystem A got unexpected command: Nil")
levels_logger
|> error(
"Exiting hyperspace due to system failure",
Error("Subsystem A quit unexpectedly"),
)
levels_logger
|> fatal(
"Could not reboot shields after exiting hyperspace",
Error([
    "ENEMY SHIP DETECTED", "ACTIVATE_SHIELDS", "REBOOT_SHIELDS",
    "REBOOT_FAILURE",
]),
)
```

> <span style="color:gray">2022-12-25T16:18:51.542Z</span> | <span style="color:cyan;font-weight:lighter">TRACE</span> | <span style="color:magenta">levels_logger(<0.9.0>)</span> | Hyperdrive subsystem A entering state PRE_ACTIVE
>
> <span style="color:gray">2022-12-25T16:18:51.542Z</span> | <span style="color:cyan">DEBUG</span> | <span style="color:magenta">levels_logger(<0.9.0>)</span> | Hyperdrive subsystems states: A=PRE_ACTIVE, B=RUNNING
>
> <span style="color:gray">2022-12-25T16:18:51.542Z</span> | <span style="color:green">INFO</span> | <span style="color:magenta">levels_logger(<0.9.0>)</span> | Entering hyperspace
>
> <span style="color:gray">2022-12-25T16:18:51.542Z</span> | <span style="color:yellow">WARNING</span> | <span style="color:magenta">levels_logger(<0.9.0>)</span> | Hyperdrive subsystem A got unexpected command: Nil
>
> <span style="color:gray">2022-12-25T16:18:51.542Z</span> | <span style="color:red">ERROR</span> | <span style="color:magenta">levels_logger(<0.9.0>)</span> | Exiting hyperspace due to system failure | Error("Subsystem A quit unexpectedly")
>
> <span style="color:gray">2022-12-25T16:18:51.560Z</span> | <span style="color:red;font-weight:bold">FATAL</span> | <span style="color:magenta">levels_logger(<0.9.0>)</span> | Could not reboot shields after exiting hyperspace | Error(["ENEMY SHIP DETECTED", "ACTIVATE_SHIELDS", "REBOOT_SHIELDS", "REBOOT_FAILURE"])

The example above also shows how to attach error information to a log-message. Errors can be attached to error and fatal logs and can be any Error result. The default serializer will use `string.inspect` to print the error to the terminal.

# Usage

## Building a logger

The base type in Glimt is the `Logger`. A logger can have a name, a min level (messages below this level will not be logged at all). Futhermore the logger can be associated with one or more `instances`. An instance in responsible for dispatching log-messages to a specific target and in a specific format. The examples above used the `stdout-dispatcher` combined with the `basic-serializer` and the `new_stdout` is a convenience method for getting a logger with that specific setup. However it is also possible to start with an empty logger and the customize it in order to get more granular control. The following example builds the exact same logger as in the first example.

```gleam
import gleam/option.{None}
import glimt.{ALL, TRACE, Direct}
import glimt/log_message.{level_value}
import glimt/serializer/basic.{basic_serializer}
import glimt/dispatcher/stdout.{dispatcher}

let custom_logger =
new("custom_logger")
|> level(ALL)
|> append_instance(Direct(
    None,
    level_value(TRACE),
    dispatcher(basic_serializer),
))
custom_logger
|> info("Entering hyperspace")
```

## Dispatchers and serializers

This example shows some important aspects of the Glimt architecture. First of all we can see the the stdout-dispatcher that was mentioned is created by providing a serializer (in this case the `basic_serializer`). However the dispatcher is just a function that takes a LogMessage and returns Nil (`fn (LogMessage) -> Nil`). Futhermore the built-in `stdout-dispatcher` in created using a serializer which is a function that turns a `LogMessage` into a `String`. This makes is very easy to plug in specialized serializers into a logger. For example one could build a serializer that only prints the message field of the log_message.

```gleam
let message_logger =
new("message_logger")
|> level(ALL)
|> append_instance(Direct(
    None,
    level_value(TRACE),
    dispatcher(fn(log_message) { log_message.message }),
))
message_logger
|> warning(
"An important message to all our travelers. We are being attacked by enemy ships.",
)
```

## Dispatching strategies

Another important aspect of the above examples is that the instance is constructed with the `Direct` constructor. This is one of the two dispatching strategies that Glimt supports and it means that the dispatcher will run synchronously in the same process as the code that logs the message. The other strategy is enabled by the `Actor` logger instance constructor and enables the actual dispatching of log-messages to be executed in a different process and only triggered by a message sent from the current process. The following example shows how we can utilize the convenience method `start_instance` to start an instance that runs in a separate process and logs to stdout.

```gleam
assert Ok(actor_instance) =
start_instance("actor_instance", TRACE, dispatcher(basic_serializer))

let actor_logger =
new("actor_logger")
|> level(INFO)
|> append_instance(actor_instance)

actor_logger
|> trace("Cutting the blue wire")
actor_logger
|> info("Bomb disarmed 💣")
```

> <span style="color:gray">2022-12-25T18:11:41.608Z</span> | <span style="color:green">INFO</span> | <span style="color:magenta">actor_logger(<0.9.0>)/actor_instance(<0.87.0>)</span> | Bomb disarmed 💣

Note that both the calling pid and the actor pid are logged together with the name of the logger and logger instance. Another interesting aspect of this example is that the accepted log-level is set both for the logger and the instance. The level of the logger will be checked first and this is why we only see one of the messages logged in the example.

## JSON
Glimt comes with a build in JSON serializer (using [gleam_json](https://github.com/gleam-lang/json)). It can be used together with any dispatcher to dispatch logs in JSON format. The following example show how to output JSON to stdout.

```gleam
let json_logger =
new("json_logger")
|> level(TRACE)
|> append_instance(Direct(
    None,
    level_value(TRACE),
    dispatcher(new_json_serializer()),
))
json_logger
|> info("Hi Hypsipyle, it's me Thoas")
```

```json
{"time":"2022-12-25T20:11:20.350Z","name":"json_logger","pid":"<0.9.0>","instance_name":null,"instance_pid":null,"level":"INFO","message":"Hi Hypsipyle, it's me Thoas","error":null}
```

## Additional data

If there is a need to attach additional data to the log-message it is possible to do this with the `log_with_data` function. This means that all logger instances of the logger need to accept data of a specific type. One easy way to accomplish this is to use the `json_serializer_with_data` which accepts an additional serializer function which should take a parameter of the specified type and return a `gleam_json` Json-type which will be used to serialize the data and insert under the `"data"`-key in the JSON log-message. The following example show how to do this.

Let say we have a type like this:

```gleam
type Data {
  Data(user_id: String, trace_id: String)
}
```

In order to serialize the additional data we can use the builder in the `json` module to attach a serializer for the custom data-type. To log the data the `log_with_data` should be used.

```gleam
let data_serializer = fn(data: Data) {
gjson.object([
    #("user_id", gjson.string(data.user_id)),
    #("trace_id", gjson.string(data.trace_id)),
])
}

let data_logger =
new("data_logger")
|> level(TRACE)
|> append_instance(Direct(
    None,
    level_value(TRACE),
    dispatcher(
    builder()
    |> add_standard_log_message()
    |> add_data(data_serializer)
    |> build(),
    ),
))
data_logger
|> log_with_data(
TRACE,
"Fetching user achievements",
Data("JohnBjrk", "322f38e8-d0a5-43f2-9590-6f435a9b5e41"),
)
```

> NOTE: `gleam_json` was imported as `import gleam/json as gjson` to avoid naming conflict with Glimts `json`module

Of course if there is need for a more specific JSON serialization of the whole log-message a custom-written serializer can be supplied to the dispatcher.

## Logger context

Sometimes it is useful for always log some data from the context. In order to do this we can use the `with_context` method which accepts a custom context and returns a logger which will include this context in all dispatched log-messages. The context can be serialized using the same strategy as for additional data using the `add_context` in the json serializer builder.

The following example adds some information from a `gleam_http` request to the log-message.

```gleam
let request_serializer = fn(request: Request(BitString)) {
gjson.object([
    #(
    "request",
    gjson.object([
        #("method", gjson.string(method_to_string(request.method))),
        #("path", gjson.string(request.path)),
    ]),
    ),
])
}

let context_logger =
new("context_logger")
|> level(TRACE)
|> append_instance(Direct(
    None,
    level_value(TRACE),
    dispatcher(
    builder()
    |> add_standard_log_message()
    |> add_context(request_serializer)
    |> build(),
    ),
))

let logger_with_request =
context_logger
|> with_context(
    request.new()
    |> set_path("api/login"),
)

logger_with_request
|> info("User successfully logged in")
```

## Erlang logger integration

It is possible to use the erlang built in [logger](https://www.erlang.org/doc/apps/kernel/logger_chapter.html) as a dispatcher in Glimt. There are two slightly different dispatchers that can be added to a logger to accomplish this: `logger_dispatch` and `logger_report_dispatch`. It is also possible to configure the erlang logger to use Glimt formatting. The following example uses the `basic_formatter` together with `logger_dispatch` to log an error. The `logger_dispatch` will add the message as a string.

```gleam
let logger_logger =
new("logger_logger")
|> level(TRACE)
|> append_instance(Direct(None, level_value(TRACE), logger_dispatch))

basic_formatter.use_with_handler("default")
logger_logger
|> error(
"Could not connect to database",
Error("Connection timeout: 127:0.0.1:5432"),
)
```

This will produce the following output:

> <span style="color:gray">2023-01-05T23:07:13.081161+01:00</span> | <span style="color:red">error</span> | <span style="color:magenta">logger_logger(<0.9.0>)</span> | Could not connect to database | Error("Connection timeout: 127:0.0.1:5432")

Note that we are setting the formatter for the `default` logger handler. This means that any log-message sent to the erlang logger will use this format.

The `logger_report_dispatch` will log a report instead of a plain string (which will include the message and other data). This is useful in combination with a logger with `context` and/or `data` since these two will be merged into the report. The following example combines the two:

```gleam
let report_logger =
new("report_logger")
|> level(TRACE)
|> append_instance(Direct(None, level_value(TRACE), logger_report_dispatch))

report_logger
|> with_context([
#("host", "blue-panda.fly.dev"),
#("url", "users"),
#("params", "token=48dhf8h826ad876f78&"),
])
|> log_with_data(
INFO,
"Successfully fetched user data",
[#("username", "JohnBjrk"), #("github_url", "https://github.com/JohnBjrk")],
)
```

It gives the following output:

> <span style="color:gray">2023-01-05T23:07:13.084284+01:00</span> | <span style="color:green">notice</span> | <span style="color:magenta">report_logger(<0.9.0>)</span> | (github_url => https://github.com/JohnBjrk, host => blue-panda.fly.dev, msg => Successfully fetched user data, params => token=48dhf8h826ad876f78&, url => users, username => JohnBjrk)

It is also possible to make the output json from the erlang logger. The following line changes the `default` handler to output json:.

```gleam
json_formatter.use_with_handler("default")
```

With this the two examples above will output the following:

```json
{"error":"Error(\"Connection timeout: 127:0.0.1:5432\")","time":1672958146686409,"time_string":"2023-01-05T23:35:46.686409+01:00","message":"Could not connect to database"}
{"time":1672958146686453,"time_string":"2023-01-05T23:35:46.686453+01:00","github_url":"https://github.com/JohnBjrk","host":"blue-panda.fly.dev","msg":"Successfully fetched user data","params":"token=48dhf8h826ad876f78&","url":"users","username":"JohnBjrk"}
```

## Todo

These are some future improvements currently on the road-map for the Glimt library.

- [ ] Add overload protection for Actor dispatchers
- [ ] Add support for writing custom erlang logger handlers
    - Utilize overload protection
- [ ] File-based config for setting log-levels of loggers based on name
    - Make it possible to override log-levels in libs by setting them in config file
- [ ] File-dispatcher
    - Write log messages to a file. Should probably be implemented as an actor.
    - Support log-rotation?
- [ ] External log service dispatchers
    - Dispatch logs to an external service (rollbar, loggly ..). This is probably best done in a separate repository which implements a specific external service.
- [ ] Dispatcher that use stderr
    - Maybe there is a need to use stderr for output of error log-messages.
