defmodule SpecForgeWebWeb.Router do
  use SpecForgeWebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SpecForgeWebWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SpecForgeWebWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # API routes
  scope "/api", SpecForgeWebWeb.Api do
    pipe_through :api

    post "/task", TaskController, :create
    post "/system", SystemController, :create
    post "/plan", PlanController, :create
    get "/status/:id", StatusController, :show
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:specforge_web, :dev_routes) do

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
