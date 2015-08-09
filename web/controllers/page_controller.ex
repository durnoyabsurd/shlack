defmodule Shlack.PageController do
  use Shlack.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
