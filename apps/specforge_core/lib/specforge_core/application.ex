defmodule SpecforgeCore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Get cache configuration from environment
    cache_config = [
      limit: get_env_int("CACHE_MAX_SIZE", 100),
      ttl: get_env_int("CACHE_TTL", 3600) * 1000  # Convert to milliseconds
    ]
    
    children = [
      # Start the cache
      {SpecforgeCore.Cache, cache_config}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SpecforgeCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  defp get_env_int(key, default) do
    case System.get_env(key) do
      nil -> default
      value -> 
        case Integer.parse(value) do
          {int, _} -> int
          _ -> default
        end
    end
  end
end
