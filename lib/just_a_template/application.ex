defmodule JustATemplate.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},
      JustATemplateWeb.Telemetry,
      JustATemplate.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:just_a_template, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:just_a_template, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: JustATemplate.PubSub},
      # Start a worker by calling: JustATemplate.Worker.start_link(arg)
      # {JustATemplate.Worker, arg},
      # Start to serve requests, typically the last entry
      JustATemplateWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JustATemplate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    JustATemplateWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") == nil
  end
end
