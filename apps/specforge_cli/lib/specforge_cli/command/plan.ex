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
    IO.puts("""
    spec plan - Convert a system design into implementation tasks

    Usage:
      spec plan --from <design.md> [options]

    Options:
      --from <file>       Design document (required)
      --to <file|dir>     Output location
      --model <model>     LLM model override
      --format <format>   Output format (md|json|yaml)
      --slice             Slice into phase files
      --dir <dir>         Output directory for slices

    Examples:
      spec plan --from design.md
      spec plan --from design.md --slice --dir phases/
    """)
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
      IO.puts("Plan generation from #{opts[:from]} not yet implemented.")
      
      if opts[:slice] do
        IO.puts("Would slice output into directory: #{opts[:dir] || "./"}")
      end
    else
      IO.puts("Error: --from option is required")
      help()
    end
  end
end