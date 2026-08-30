defmodule MusicStudioWeb.PageController do
  use MusicStudioWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
