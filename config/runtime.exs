import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

# Load environment variables from .env file if it exists
if File.exists?(".env") do
  for line <- File.stream!(".env"),
      line = String.trim(line),
      line != "",
      not String.starts_with?(line, "#"),
      [key | rest] = String.split(line, "=", parts: 2),
      value = Enum.join(rest, "=") do
    System.put_env(String.trim(key), String.trim(value))
  end
end

# Common runtime configuration
config :specforge_core,
  cache_backend: System.get_env("CACHE_BACKEND", "mem"),
  cache_ttl: String.to_integer(System.get_env("CACHE_TTL", "3600")),
  cache_max_size: String.to_integer(System.get_env("CACHE_MAX_SIZE", "100")),
  output_dir: System.get_env("OUTPUT_DIR", "./specs"),
  default_model: System.get_env("DEFAULT_MODEL", "openai"),
  enable_web_search: System.get_env("ENABLE_WEB_SEARCH", "false") == "true"

# LLM configuration
if api_key = System.get_env("OPENAI_API_KEY") do
  config :ex_llm, :openai, api_key: api_key
end

if api_key = System.get_env("ANTHROPIC_API_KEY") do
  config :ex_llm, :anthropic, api_key: api_key
end

if host = System.get_env("OLLAMA_HOST") do
  config :ex_llm, :ollama, host: host
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/specforge start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :specforge_web, SpecForgeWebWeb.Endpoint, server: true
end

if config_env() == :prod and Application.spec(:specforge_web) do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :specforge_web, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :specforge_web, SpecForgeWebWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :specforge_web, SpecForgeWebWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :specforge_web, SpecForgeWebWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :specforge_web, SpecForgeWeb.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end

