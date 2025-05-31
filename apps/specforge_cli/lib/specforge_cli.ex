defmodule SpecforgeCli do
  @moduledoc """
  Command-line interface for SpecForge.
  Provides the `spec` command with task, system, and plan subcommands.
  """

  alias SpecforgeCli.Command.{Task, System, Plan}

  @version Mix.Project.config()[:version]

  def main(args \\ []) do
    args
    |> parse_args()
    |> run_command()
  rescue
    e ->
      Owl.IO.puts([:red, "Error: #{Exception.message(e)}"])
      :erlang.halt(1)
  end

  defp parse_args(args) do
    {opts, cmd_args, _invalid} = OptionParser.parse(args,
      switches: [
        help: :boolean,
        version: :boolean,
        cache: :string,
        cache_ttl: :integer,
        clear_cache: :boolean,
        output_dir: :string,
        quiet: :boolean,
        verbose: :boolean
      ],
      aliases: [
        h: :help,
        v: :version,
        q: :quiet
      ]
    )

    {opts, cmd_args}
  end

  defp run_command({opts, []}), do: run_command({opts, ["help"]})
  
  defp run_command({opts, [cmd | args]}) do
    cond do
      opts[:help] -> show_help(cmd)
      opts[:version] -> show_version()
      true ->
        case cmd do
          "task" -> Task.run(args, opts)
          "system" -> System.run(args, opts)
          "plan" -> Plan.run(args, opts)
          "help" -> show_help(List.first(args))
          _ -> 
            Owl.IO.puts([:red, "Unknown command: #{cmd}"])
            show_help()
            :erlang.halt(1)
        end
    end
  end

  defp show_version do
    Owl.IO.puts([:green, "SpecForge v#{@version}"])
  end

  defp show_help(nil), do: show_help()
  defp show_help("task"), do: Task.help()
  defp show_help("system"), do: System.help()
  defp show_help("plan"), do: Plan.help()
  defp show_help(_), do: show_help()

  defp show_help do
    Owl.IO.puts([
      [:bright, "SpecForge"],
      " - Next-Generation Task & Design Spec Assistant\n\n",
      [:yellow, "Usage:"],
      "\n  spec <command> [options]\n\n",
      [:yellow, "Commands:"],
      "\n  ",
      [:cyan, "task"], "    Analyze a task and generate an actionable plan\n  ",
      [:cyan, "system"], "  Create or refine a system design\n  ",
      [:cyan, "plan"], "    Convert a system design into implementation tasks\n\n",
      [:yellow, "Global Options:"],
      "\n  ",
      [:cyan, "-h, --help"], "     Show help\n  ",
      [:cyan, "-v, --version"], "  Show version\n  ",
      [:cyan, "-q, --quiet"], "    Suppress output\n  ",
      [:cyan, "--verbose"], "      Show detailed output\n  ",
      [:cyan, "--cache"], "        Enable caching (mem|disk)\n  ",
      [:cyan, "--output-dir"], "   Set output directory\n\n",
      "Run 'spec <command> --help' for command-specific options.\n"
    ])
  end
end
