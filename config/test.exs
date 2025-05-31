import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :specforge_web, SpecForgeWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "H+3UEZd6N8EHx9VRRcN0dLgCGDzlLyWEbRuOz0wM5lVVOhTHO0917U6fQMIyganh",
  server: false

# In test we don't send emails.
config :specforge_web, SpecForgeWeb.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :specforge_web, SpecForgeWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "W0GtiF8ScAkdyc5dcbYgZWUqm2FPSSYgGUmCcsGKOFKHXiDvyNBB8msfltjBGr++",
  server: false

# In test we don't send emails.
config :specforge_web, SpecForgeWeb.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
