defmodule SpecforgeCli.Command.Task do
  @moduledoc """
  Implementation of the 'spec task' command.
  Analyzes task descriptions and generates actionable plans.
  """

  alias SpecforgeCore.Impl.TaskPlannerImpl

  def run(args, global_opts) do
    {opts, remaining_args, _} = parse_options(args)
    
    if opts[:help] do
      help()
    else
      task_description = get_task_description(remaining_args, opts)
      execute_task(task_description, merge_options(opts, global_opts))
    end
  end

  def help do
    Owl.IO.puts([
      [:bright, "spec task"],
      " - Analyze a task and generate an actionable plan\n\n",
      [:yellow, "Usage:"],
      "\n  spec task <task-description> [options]",
      "\n  spec task - [options]                    # Read from stdin\n\n",
      [:yellow, "Options:"],
      "\n  ",
      [:cyan, "--from <file>"], "       Read task from file\n  ",
      [:cyan, "--to <file|dir>"], "     Write output to file or directory\n  ",
      [:cyan, "--model <model>"], "     LLM model (e.g., openai:gpt-4o)\n  ",
      [:cyan, "--search"], "            Augment with web context\n  ",
      [:cyan, "--template <file>"], "   Custom template file\n  ",
      [:cyan, "--no-validate"], "       Skip validation\n\n",
      [:yellow, "Examples:"],
      "\n  spec task \"Implement user authentication\"\n  ",
      "spec task --from requirements.txt --to specs/\n  ",
      "echo \"Build a REST API\" | spec task -\n"
    ])
  end

  defp parse_options(args) do
    OptionParser.parse(args,
      switches: [
        help: :boolean,
        from: :string,
        to: :string,
        model: :string,
        search: :boolean,
        template: :string,
        validate: :boolean
      ],
      aliases: [h: :help]
    )
  end

  defp get_task_description(["-"], _opts) do
    IO.read(:all)
  end

  defp get_task_description([], %{from: from}) when is_binary(from) do
    case File.read(from) do
      {:ok, content} -> content
      {:error, reason} -> 
        raise "Failed to read file #{from}: #{reason}"
    end
  end

  defp get_task_description(args, _opts) when length(args) > 0 do
    Enum.join(args, " ")
  end

  defp get_task_description(_, _) do
    raise "No task description provided. Use --from, provide text, or pipe to stdin."
  end

  defp merge_options(opts, global_opts) do
    Map.merge(
      Enum.into(global_opts, %{}),
      Enum.into(opts, %{})
    )
  end

  defp execute_task(description, opts) do
    with_progress("Analyzing task...", fn ->
      case TaskPlannerImpl.analyze_task(description, opts) do
        {:ok, result} -> 
          handle_output(result, opts)
        {:error, reason} ->
          raise "Task analysis failed: #{inspect(reason)}"
      end
    end)
  end

  defp handle_output(_result, %{quiet: true}), do: :ok
  
  defp handle_output(result, %{to: output} = opts) when is_binary(output) do
    output_path = if File.dir?(output) do
      timestamp = DateTime.utc_now() |> DateTime.to_unix()
      Path.join(output, "task_#{timestamp}.md")
    else
      output
    end

    case File.write(output_path, result) do
      :ok -> 
        unless opts[:quiet] do
          Owl.IO.puts([:green, "✓ Output written to: #{output_path}"])
        end
      {:error, reason} ->
        raise "Failed to write output: #{reason}"
    end
  end

  defp handle_output(result, _opts) do
    Owl.IO.puts(result)
  end

  defp with_progress(message, fun) do
    # Simplified progress indicator for now
    Owl.IO.puts([:cyan, "⏳ #{message}"])
    
    try do
      result = fun.()
      Owl.IO.puts([:green, "✓ Done!"])
      result
    rescue
      e ->
        Owl.IO.puts([:red, "✗ Failed!"])
        reraise e, __STACKTRACE__
    end
  end
end