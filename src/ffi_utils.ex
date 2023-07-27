defmodule FFIUtils do
  def format_time(time, fmt_str) do
    time
    |> DateTime.from_unix!()
    |> Calendar.strftime(fmt_str)
  end

  def clock_time(time) do
    datetime = time
    |> DateTime.from_unix!()

    {datetime.hour, datetime.minute, datetime.second}
  end
end
