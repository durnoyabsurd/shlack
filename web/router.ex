defmodule Shlack.Router do
  use Shlack.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end
  
  scope "/", Shlack do
    pipe_through :browser

    get "/", PageController, :index
  end
end
