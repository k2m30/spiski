defmodule Discuss.Worker do
  @moduledoc false

  use GenServer

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state)
  end

  def init(state) do
    :ets.new(:db, [:set, :public, :named_table])
    do_work()
    schedule_work() # Schedule work to be performed at some point
    {:ok, state}
  end

  def handle_info(:work, state) do
    do_work()
    schedule_work() # Reschedule once more
    {:noreply, state}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 5 * 60 * 1000)
  end

  defp do_work do
    {:ok, pid} = GSS.Spreadsheet.Supervisor.spreadsheet("1NSxHGQJMDg3yGnydYBu4sA2IrXtSVGYB4EPYF9EkvYc", list_name: "15.11")
    {:ok, rows} = GSS.Spreadsheet.read_rows(pid, 1, 10, column_to: 23, pad_empty: true)
    [headers | data ] = rows
    headers |> IO.inspect

    :ets.insert(:db, {:headers, headers})
    Enum.each(data, fn row -> :ets.insert(:db, [Enum.at(row, 1), row] |> List.flatten |> List.to_tuple)  end)
#    :ets.match_object(:db, {:_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, "Аносов", :_, :_, :_, :_, :_, :_, :_, :_, :_}) |> IO.inspect
  end
end