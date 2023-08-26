defmodule RateLimiter.TokenBucketTest do
  use ExUnit.Case, async: true

  setup do
    :ets.delete_all_objects(:bucket_table)

    {:ok, some_value: "example"}
  end

  test "consume tokens within limit" do
    identifier = "127.0.0.1"
    assert :ok == RateLimiter.TokenBucket.consume(identifier, 1)
  end

  test "consume tokens beyond limit" do
    identifier = "127.0.0.2"

    assert {:error, "Insufficient tokens"} == RateLimiter.TokenBucket.consume(identifier, 101)
  end

  test "refill tokens over time" do
    identifier = "127.0.0.3"

    assert :ok == RateLimiter.TokenBucket.consume(identifier, 100)

    :timer.sleep(5000)

    assert :ok == RateLimiter.TokenBucket.consume(identifier, 20)
    assert {:error, "Insufficient tokens"} == RateLimiter.TokenBucket.consume(identifier, 10)
  end
end
