defmodule SpecforgeCli.Command.System do
  @moduledoc """
  Implementation of the 'spec system' command.
  """

  def run(_args, _global_opts) do
    help()
  end

  def help do
    Owl.IO.puts([:yellow, "System command not yet implemented."])
  end
end