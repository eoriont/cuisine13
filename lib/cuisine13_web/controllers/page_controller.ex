defmodule Cuisine13Web.PageController do
  use Cuisine13Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
