defmodule DiscussWeb.PageController do
  use DiscussWeb, :controller

  def index(conn, params) do
    name = params["search"]["name"]
    raw_data = :ets.match_object(:db, {:_, :_, :_, :_, :_, name})
    headers = :ets.lookup(:db, :headers)
    raw_data
    |> IO.inspect

    data = Enum.map(
             raw_data,
             fn e ->
               Enum.zip(headers[:headers], Tuple.to_list(e))
               |> Enum.into(%{})
               |> Map.drop(["", "#"]) end
           )
           |> IO.inspect

    render(conn, "index.html", name: name, data: data)
  end
end
