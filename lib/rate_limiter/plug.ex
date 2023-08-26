defmodule RateLimiter.Plug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, %{limiter: limiter_module} = opts) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string

    case limiter_module.consume(ip, 1) do
      :ok -> conn
      :error -> conn |> send_resp(429, "Too many requests") |> halt()
    end
  end
end
