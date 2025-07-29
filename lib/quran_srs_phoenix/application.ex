defmodule QuranSrsPhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      QuranSrsPhoenixWeb.Telemetry,
      QuranSrsPhoenix.Repo,
      {DNSCluster, query: Application.get_env(:quran_srs_phoenix, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: QuranSrsPhoenix.PubSub},
      # Start a worker by calling: QuranSrsPhoenix.Worker.start_link(arg)
      # {QuranSrsPhoenix.Worker, arg},
      # Start to serve requests, typically the last entry
      QuranSrsPhoenixWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: QuranSrsPhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QuranSrsPhoenixWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
