defmodule SpiskiWeb.PageController do
  use SpiskiWeb, :controller

  def index(conn, params) do
    name = (params["search"]["name"] || "") |> String.trim |> String.capitalize
    data = search(name)
    data |> IO.inspect
    render(conn, "index.html", name: name, data: data)
  end

  defp search(name) when name != "" do
    raw_data = :ets.match_object(:db, {:_, :_, :_, :_, :_, name})
    headers = :ets.lookup(:db, :headers)

    data = Enum.map(
      raw_data,
      fn e ->
        Enum.zip(headers[:headers], Tuple.to_list(e))
        |> Enum.into(%{})
        |> Map.drop(["", "#"])
      end
    )
  end

  defp search(_), do: []
end
