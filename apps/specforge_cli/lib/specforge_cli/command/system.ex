defmodule SpecforgeCli.Command.System do
  @moduledoc """
  Implementation of the 'spec system' command.
  Creates or refines system designs.
  """

  alias SpecforgeCore.Impl.SystemDesignerImpl
  alias SpecforgeCore.Impl.SlicerImpl

  def run(args, global_opts) do
    {opts, _remaining_args, _} = parse_options(args)
    
    if opts[:help] do
      help()
    else
      execute_system(merge_options(opts, global_opts))
    end
  end

  def help do
    IO.puts("""
    spec system - Create or refine a system design

    Usage:
      spec system [options]

    Options:
      --from <file>         Existing design document
      --interactive        Guided interview mode
      --format <format>    Output format (md|json|yaml)
      --conventions <file> Team style guide
      --deep-task          Run spec plan on subtasks
      --slice              Slice output into phase files
      --dir <dir>          Output directory for slices

    Examples:
      spec system --interactive
      spec system --from design.md --format json
    """)
  end

  defp parse_options(args) do
    OptionParser.parse(args,
      switches: [
        help: :boolean,
        from: :string,
        interactive: :boolean,
        format: :string,
        conventions: :string,
        deep_task: :boolean,
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

  defp execute_system(opts) do
    # Default to interactive if no --from specified
    opts = if !opts[:from] && !opts[:interactive], do: Map.put(opts, :interactive, true), else: opts
    
    with {:ok, design_output} <- SystemDesignerImpl.design_system(opts) do
      handle_output(design_output, opts)
      
      # Ask about slicing if interactive
      if opts[:interactive] && SystemDesignerImpl.prompt_extract_phases() do
        slice_design(design_output, opts)
      end
      
      # Ask about generating plan if interactive
      if opts[:interactive] && prompt_generate_plan() do
        IO.puts("\n💡 Run 'spec plan --from <design-file>' to generate implementation tasks.")
      end
    else
      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}")
        :erlang.halt(1)
    end
  end

  defp handle_output(_result, %{quiet: true}), do: :ok
  
  defp handle_output(result, %{to: output} = opts) when is_binary(output) do
    output_path = if File.dir?(output) do
      timestamp = DateTime.utc_now() |> DateTime.to_unix()
      Path.join(output, "system_design_#{timestamp}.md")
    else
      output
    end

    case File.write(output_path, result) do
      :ok -> 
        unless opts[:quiet] do
          IO.puts("✓ Design written to: #{output_path}")
        end
      {:error, reason} ->
        raise "Failed to write output: #{reason}"
    end
  end

  defp handle_output(result, opts) do
    output_path = get_default_output_path(opts)
    File.mkdir_p!(Path.dirname(output_path))
    
    case File.write(output_path, result) do
      :ok ->
        unless opts[:quiet] do
          IO.puts("\n✓ Design written to: #{output_path}")
        end
      {:error, reason} ->
        raise "Failed to write output: #{reason}"
    end
  end

  defp get_default_output_path(opts) do
    output_dir = opts[:output_dir] || "specs"
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    format = opts[:format] || "md"
    extension = case format do
      :json -> "json"
      :yaml -> "yaml"
      _ -> "md"
    end
    Path.join(output_dir, "system_design_#{timestamp}.#{extension}")
  end

  defp slice_design(content, opts) do
    output_dir = opts[:dir] || "specs/phases"
    
    case SlicerImpl.slice_document(content, %{output_dir: output_dir}) do
      {:ok, _slices} ->
        IO.puts("✓ Design sliced into phases in: #{output_dir}")
      {:error, reason} ->
        IO.puts("Failed to slice design: #{inspect(reason)}")
    end
  end

  defp prompt_generate_plan do
    case prompt_yes_no("Would you like to generate an implementation plan from this design?") do
      {:ok, answer} -> answer
      {:error, _} -> false
    end
  end

  defp prompt_yes_no(question) do
    IO.puts("\n#{question} (y/n)")
    case IO.gets("> ") |> String.trim() |> String.downcase() do
      "y" -> {:ok, true}
      "yes" -> {:ok, true}
      "n" -> {:ok, false}
      "no" -> {:ok, false}
      _ -> 
        IO.puts("Please answer 'y' or 'n'")
        prompt_yes_no(question)
    end
  end
end