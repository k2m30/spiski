require Logger

defmodule SpiskiWeb.
          PageController do
  use SpiskiWeb, :controller

  def index(conn, params) do
    names = strip(params["q"] || "")
    results = names
              |> Enum.map(&(search(&1)))

    data = Enum.zip(names, results)
           |> Enum.into(%{})

    data
    |> Logger.info

    render(
      conn,
      "index.html",
      names: names,
      data: data,
      db_size: :ets.info(:db)[:size]
    )
  end

  def api(conn, params) do
    names = strip(params["q"] || "")
    results = names
              |> Enum.map(&(search(&1)))

    data = Enum.zip(names, results)
           |> Enum.into(%{})

    data
    |> Logger.info

    json(conn, data)
  end

  defp strip(name) do
    name
    |> String.split(",")
    |> Enum.map(
         fn x ->
           String.split(x, "-")
           |> Enum.map(
                fn a ->
                  String.capitalize(
                    a
                    |> String.trim
                    |> String.split
                    |> (List.first) || ""
                  )
                end
              )
           |> Enum.join("-")
           |> String.trim
           |> String.replace("ё", "е")
         end
       )
    |> Enum.reject(&(&1 == ""))

  end

  defp search(name) when name != "" do
    raw_data = :ets.match_object(
      :db,
      {:_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, name}
    )
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
