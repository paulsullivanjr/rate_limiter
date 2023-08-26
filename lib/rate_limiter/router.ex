defmodule RateLimiter.Router do
  use Plug.Router

  plug(RateLimiter.Plug, limiter: RateLimiter.TokenBucket)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
