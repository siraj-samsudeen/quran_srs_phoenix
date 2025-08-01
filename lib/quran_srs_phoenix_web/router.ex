defmodule QuranSrsPhoenixWeb.Router do
  use QuranSrsPhoenixWeb, :router

  import QuranSrsPhoenixWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {QuranSrsPhoenixWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", QuranSrsPhoenixWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", QuranSrsPhoenixWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:quran_srs_phoenix, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: QuranSrsPhoenixWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", QuranSrsPhoenixWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{QuranSrsPhoenixWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      
      # Hafiz management routes
      live "/hafizs", HafizLive.Index, :index
      live "/hafizs/new", HafizLive.Form, :new
      live "/hafizs/:id", HafizLive.Show, :show
      live "/hafizs/:id/edit", HafizLive.Form, :edit
      
      # Permission configuration routes
      live "/permissions", RelationshipPermissionLive.Index, :index
      live "/permissions/new", RelationshipPermissionLive.Form, :new
      live "/permissions/:id", RelationshipPermissionLive.Show, :show
      live "/permissions/:id/edit", RelationshipPermissionLive.Form, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", QuranSrsPhoenixWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{QuranSrsPhoenixWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
