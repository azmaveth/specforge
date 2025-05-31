defmodule SpecforgeCli.Command.Plan do
  @moduledoc """
  Implementation of the 'spec plan' command.
  Converts system designs into implementation plans.
  """

  # alias SpecforgeCore.Impl.PlanGeneratorImpl

  def run(args, global_opts) do
    {opts, _remaining_args, _} = parse_options(args)
    
    if opts[:help] do
      help()
    else
      execute_plan(merge_options(opts, global_opts))
    end
  end

  def help do
    Owl.IO.puts([
      [:bright, "spec plan"],
      " - Convert a system design into implementation tasks\n\n",
      [:yellow, "Usage:"],
      "\n  spec plan --from <design.md> [options]\n\n",
      [:yellow, "Options:"],
      "\n  ",
      [:cyan, "--from <file>"], "       Design document (required)\n  ",
      [:cyan, "--to <file|dir>"], "     Output location\n  ",
      [:cyan, "--model <model>"], "     LLM model override\n  ",
      [:cyan, "--format <format>"], "   Output format (md|json|yaml)\n  ",
      [:cyan, "--slice"], "             Slice into phase files\n  ",
      [:cyan, "--dir <dir>"], "         Output directory for slices\n\n",
      [:yellow, "Examples:"],
      "\n  spec plan --from design.md\n  ",
      "spec plan --from design.md --slice --dir phases/\n"
    ])
  end

  defp parse_options(args) do
    OptionParser.parse(args,
      switches: [
        help: :boolean,
        from: :string,
        to: :string,
        model: :string,
        format: :string,
        slice: :boolean,
        dir: :string
      ],
      aliases: [h: :help]
    )
  end

  defp merge_options(opts, global_opts) do
    Map.merge(
      Enum.into(global_opts, %{}),
      Enum.into(opts, %{})
    )
  end

  defp execute_plan(opts) do
    # Stub implementation
    if opts[:from] do
      Owl.IO.puts([:yellow, "Plan generation from #{opts[:from]} not yet implemented."])
      
      if opts[:slice] do
        Owl.IO.puts("Would slice output into directory: #{opts[:dir] || "./"}")
      end
    else
      Owl.IO.puts([:red, "Error: --from option is required"])
      help()
    end
  end
end