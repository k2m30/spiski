defmodule DiscussWeb.PageController do
  use DiscussWeb, :controller

  def index(conn, params) do
    name = params["search"]["name"]
    :ets.last(:db)
    |> IO.inspect
    render(conn, "index.html", name: name)
  end

  def search(conn, params) do
    name = params["search"]["name"]
    data = :ets.match_object(
      :db,
      {:_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, :_, name, :_, :_, :_, :_, :_, :_}
    )
    headers = :ets.lookup(:db, :headers)
    headers |> IO.inspect

    data = Enum.map(data, fn e -> Enum.zip(headers[:headers], Tuple.to_list(e)) |> Enum.into(%{}) end) |> IO.inspect


    render(conn, "index.html", name: name, data: data)
  end

end
