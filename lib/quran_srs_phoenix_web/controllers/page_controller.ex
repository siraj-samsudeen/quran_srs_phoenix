defmodule QuranSrsPhoenixWeb.PageController do
  use QuranSrsPhoenixWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
