defmodule SpecforgeCore.Cache do
  @moduledoc """
  Cache wrapper for SpecForge operations.
  Provides a unified interface for caching LLM responses and generated documents.
  """

  @cache_name :specforge_cache
  @default_ttl :timer.hours(1)

  @doc """
  Starts the cache supervisor.
  Called from the application supervisor.
  """
  def start_link(opts \\ []) do
    cache_opts = [
      name: @cache_name,
      limit: Keyword.get(opts, :limit, 1000),
      default_ttl: Keyword.get(opts, :ttl, @default_ttl),
      stats: true
    ]

    Cachex.start_link(@cache_name, cache_opts)
  end

  @doc """
  Gets a value from the cache.
  """
  def get(key) do
    case Cachex.get(@cache_name, key) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, value} -> {:ok, value}
      error -> error
    end
  end

  @doc """
  Puts a value in the cache with optional TTL.
  """
  def put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    case Cachex.put(@cache_name, key, value, ttl: ttl) do
      {:ok, true} -> :ok
      error -> error
    end
  end

  @doc """
  Gets a value from cache, or executes the function and caches the result.
  """
  def fetch(key, fun, opts \\ []) when is_function(fun, 0) do
    case get(key) do
      {:ok, value} ->
        {:ok, value}
      
      {:error, :not_found} ->
        case fun.() do
          {:ok, value} ->
            put(key, value, opts)
            {:ok, value}
          
          error ->
            error
        end
    end
  end

  @doc """
  Clears all entries from the cache.
  """
  def clear do
    Cachex.clear(@cache_name)
  end

  @doc """
  Deletes a specific key from the cache.
  """
  def delete(key) do
    Cachex.del(@cache_name, key)
  end

  @doc """
  Gets cache statistics.
  """
  def stats do
    Cachex.stats(@cache_name)
  end

  @doc """
  Generates a cache key for LLM operations.
  """
  def generate_key(operation, params) do
    data = {operation, params}
    :crypto.hash(:sha256, :erlang.term_to_binary(data))
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Returns a child specification for the cache.
  """
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end
end