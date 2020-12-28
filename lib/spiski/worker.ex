require Logger

defmodule Spiski.Worker do
  @moduledoc false

  use GenServer

  @lists %{
    august_begin: %{
      name: "09.08-23.08 (Весна) для публикации",
      start_index: 1_000_000,
      refresh_time: 180 * 60 * 1000
    },
    august_end: %{
      name: "25.08-05.09 для публикации",
      start_index: 1_100_000,
      refresh_time: 180 * 60 * 1000
    },
    september: %{
      name: "08.09-26.09 для публикации",
      start_index: 1_200_000,
      refresh_time: 180 * 60 * 1000
    },
    october: %{
      name: "Сентябрь-Октябрь для публикации",
      start_index: 1_300_000,
      refresh_time: 180 * 60 * 1000
    },
    november: %{
      name: "Ноябрь-Декабрь для публикации",
      start_index: 1_400_000,
      refresh_time: 5 * 60 * 1000
    },
    today: %{
      name: "Сегодня для публикации",
      start_index: 0,
      refresh_time: 5 * 60 * 1000
    },
    digital: %{
      name: "Оцифровка для публикации",
      start_index: 100_000,
      refresh_time: 5 * 60 * 1000
    }
  }

  @sheet_id "1NSxHGQJMDg3yGnydYBu4sA2IrXtSVGYB4EPYF9EkvYc"

  def start_link(initial_state \\ %{}) do
    GenServer.start_link(__MODULE__, initial_state)
  end

  def init(state) do
    :ets.new(:db, [:set, :public, :named_table, read_concurrency: true])
    Process.send_after(self(), :august_begin, 150 * 1000)
    Process.send_after(self(), :august_end, 120 * 1000)
    Process.send_after(self(), :september, 90 * 1000)
    Process.send_after(self(), :october, 60 * 1000)
    Process.send_after(self(), :november, 30 * 1000)
    Process.send_after(self(), :digital, 15 * 1000)
    Process.send_after(self(), :today, 1 )
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
    try do
      {:ok, pid} = GSS.Spreadsheet.Supervisor.spreadsheet(@sheet_id, list_name: @lists[month][:name])
      case GSS.Spreadsheet.rows(pid) do
        {:ok, rows_number} -> batch_size = 300
                              start_index = @lists[month][:start_index]
                              for i <- 0..div(rows_number, batch_size) do
                                respond = GSS.Spreadsheet.read_rows(
                                  pid,
                                  i * batch_size + 1,
                                  (i + 1) * batch_size,
                                  column_to: 22,
                                  pad_empty: true
                                )
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


        {:error, error} -> Logger.error error
      end
    rescue
      error -> Logger.error error
    end
  end
end