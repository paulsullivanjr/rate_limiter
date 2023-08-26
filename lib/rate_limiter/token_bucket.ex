defmodule RateLimiter.TokenBucket do
    @moduledoc """
    A rate limiter implementation using the token bucket algorithm.

    The token bucket algorithm operates on the principle of a refillable bucket holding tokens. Tokens are added
    to the bucket at a fixed rate up to a defined capacity. Each incoming request consumes one or more tokens from
    the bucket. If sufficient tokens are present, the request is allowed; otherwise, it's either denied or queued.

    ## How it works:

    1. **Bucket Capacity**: Defines the maximum number of tokens the bucket can hold. Once the bucket is full,
       additional tokens simply overflow and are discarded.

    2. **Token Refill Rate**: Specifies the rate at which tokens are added back to the bucket. For instance, if the rate
       is 5 tokens per second, then every second, 5 tokens are added to the bucket, until the bucket reaches its capacity.

    3. **Token Consumption**: When a request arrives, it attempts to consume a predefined number of tokens from the bucket:
       - If there are enough tokens in the bucket (i.e., bucket tokens >= tokens needed by the request), the necessary
         tokens are removed from the bucket and the request proceeds.
       - If there aren't enough tokens, the request is either denied or has to wait until enough tokens are available.

    The beauty of the token bucket algorithm lies in its ability to handle variable request rates, allowing for "bursts"
    of fast requests up to the bucket's capacity but maintaining a long-term average rate as determined by the refill rate.

    Note: The actual rate-limiting behavior (deny or wait) upon token insufficiency depends on the specific implementation and use-case requirements.
    """

  use GenServer
  @behaviour RateLimiter.Behaviour

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put_new(opts, :name, __MODULE__))
  end

  def init(_args) do
    capacity = Application.get_env(:rate_limiter, :default_capacity)
    fill_rate = Application.get_env(:rate_limiter, :default_fill_rate)

    unless :ets.info(:bucket_table) == :undefined do
      :ets.delete(:bucket_table)
    end

    :ets.new(:bucket_table, [:set, :named_table, :public])

    state = %{
      capacity: capacity,
      fill_rate: fill_rate
    }

    {:ok, state}
  end

  def consume(identifier, count) do
    GenServer.call(__MODULE__, {:consume, identifier, count})
  end

  def handle_call({:consume, identifier, count}, _from, state) do
    bucket = case :ets.lookup(:bucket_table, identifier) do
      [] ->
        {identifier, state.capacity, :os.system_time(:second)}
      [{_identifier, tokens, last_fill_time}] ->
        {_identifier, tokens, last_fill_time}
    end

    handle_token_consumption(bucket, count, state)
  end

  defp handle_token_consumption({identifier, tokens, last_fill_time}, count, state) do
    {new_tokens, new_last_fill_time} = refill(tokens, last_fill_time, state)

    # Try to consume
    if new_tokens >= count do
      :ets.insert(:bucket_table, {identifier, new_tokens - count, new_last_fill_time})
      {:reply, :ok, state}
    else
      {:reply, {:error, "Insufficient tokens"}, state}
    end
  end

  defp refill(tokens, last_fill_time, state) do
    current_time = :os.system_time(:second)
    elapsed_time = current_time - last_fill_time
    new_tokens = min(state.capacity, tokens + elapsed_time * state.fill_rate)

    {new_tokens, current_time}
  end
end
