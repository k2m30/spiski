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
    {:ok, pid} = GSS.Spreadsheet.Supervisor.spreadsheet("1NSxHGQJMDg3yGnydYBu4sA2IrXtSVGYB4EPYF9EkvYc", list_name: "15.11 для Публикации")
    {:ok, rows_number} = GSS.Spreadsheet.rows(pid)

    batch_size = 300
    for i <- 0..div(rows_number,batch_size) do
      {:ok, rows} = GSS.Spreadsheet.read_rows(pid, i*batch_size+1, (i+1)*batch_size, column_to: 5, pad_empty: true)
      if i == 0 do
        [headers | rows ] = rows
        :ets.insert(:db, {:headers, headers})
      end
      Enum.each(rows, fn row ->  :ets.insert(:db, row ++ [Enum.at(row, 1) |> String.split |> List.first] |> List.to_tuple)  end)
    end
  end
end