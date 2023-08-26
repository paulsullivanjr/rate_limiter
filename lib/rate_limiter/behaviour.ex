defmodule RateLimiter.Behaviour do
  @callback consume(identifier :: String.t(), count :: integer()) :: :ok | :error
end
