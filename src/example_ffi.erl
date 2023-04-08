-module(example_ffi).

-export([configure_logger_backend/0, priv_directory/0, current_timestamp/0]).

configure_logger_backend() ->
    ok = logger:set_primary_config(level, info),
    ok = logger:set_handler_config(
        default,
        formatter,
        {logger_formatter, #{
            template => [level, ": ", msg, "\n"]
        }}
    ),
    ok = logger:set_application_level(stdlib, notice),
    nil.

priv_directory() ->
    list_to_binary(code:priv_dir(sprocket)).

current_timestamp() ->
    Now = erlang:system_time(second),
    list_to_binary(calendar:system_time_to_rfc3339(Now)).
