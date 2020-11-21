require Logger

defmodule Spiski.Worker do
  @moduledoc false

  use GenServer

  @lists %{
    october: %{
      name: "Сентябрь-Октябрь для публикации",
      start_index: 1_000_000,
      refresh_time: 30 * 60 * 1000
    },
    november: %{
      name: "Ноябрь для публикации",
      start_index: 1_100_000,
      refresh_time: 5 * 60 * 1000
    },
    today: %{
      name: "Сегодня",
      start_index: 0,
      refresh_time: 5 * 60 * 1000
    }
  }

  @sheet_id "1NSxHGQJMDg3yGnydYBu4sA2IrXtSVGYB4EPYF9EkvYc"

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state)
  end

  def init(state) do
    :ets.new(:db, [:set, :public, :named_table, read_concurrency: true])
    Process.send_after(self(), :october, 30 * 1000)
    Process.send_after(self(), :november, 1)
    Process.send_after(self(), :today, 60 * 1000)
    {:ok, state}
  end

  def handle_info(month, state) do
    get_data(month)
    schedule_work(month, @lists[month][:refresh_time]) # Reschedule once more
    {:noreply, state}
  end

  defp schedule_work(msg, time) do
    Process.send_after(self(), msg, time)
  end

  defp get_data(month) do
    {:ok, pid} = GSS.Spreadsheet.Supervisor.spreadsheet(@sheet_id, list_name: @lists[month][:name])
    {:ok, rows_number} = GSS.Spreadsheet.rows(pid)

    batch_size = 300
    start_index = @lists[month][:start_index]
    for i <- 0..div(rows_number, batch_size) do
      respond = GSS.Spreadsheet.read_rows(pid, i * batch_size + 1, (i + 1) * batch_size, column_to: 22, pad_empty: true)
      case respond do
        {:ok, rows} ->

          if i == 0 do
            [headers | rows] = rows
            :ets.insert(:db, {:headers, headers})
          end

          rows
          |> Enum.with_index
          |> Enum.each(
               fn ({row, index}) ->
                 row = List.replace_at(row, 0, start_index + i * batch_size + index);
                 :ets.insert(
                   :db,
                   row ++ [
                     Enum.at(row, 1)
                     |> String.split
                     |> List.first
                   ]
                   |> List.to_tuple
                 )
               end
             )
        {:error, error} -> Logger.error error
      end
    end
  end
end