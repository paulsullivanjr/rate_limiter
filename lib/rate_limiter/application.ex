defmodule RateLimiter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    if :ets.info(:bucket_table) == :undefined do
      :ets.new(:bucket_table, [:named_table, :public, :set])
    end

    children = [
      {RateLimiter.TokenBucket, []},
      {Plug.Cowboy, scheme: :http, plug: RateLimiter.Router, options: [port: 8080]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RateLimiter.Supervisor]

    Logger.info("Starting application...")

    Supervisor.start_link(children, opts)
  end
end
