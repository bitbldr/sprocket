defmodule Sprocket do
  def format_time(time, fmt_str) do
    time
    |> DateTime.from_unix!()
    |> Calendar.strftime(fmt_str)
  end
end
