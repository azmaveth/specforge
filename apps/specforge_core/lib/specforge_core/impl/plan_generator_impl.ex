defmodule SpecforgeCore.Impl.PlanGeneratorImpl do
  @moduledoc """
  Default implementation of the PlanGenerator behaviour.
  Converts system designs into implementation plans.
  """
  @behaviour SpecforgeCore.PlanGenerator

  @impl true
  def generate_plan(options) do
    with {:ok, from_path} <- validate_from_option(options),
         {:ok, content} <- File.read(from_path),
         {:ok, tasks} <- extract_tasks(content),
         sequenced <- sequence_tasks(tasks),
         formatted <- format_plan(sequenced, Map.get(options, :format, :md)) do
      handle_output(formatted, options)
    end
  end

  @impl true
  def extract_tasks(_design_content) do
    # Stub implementation - in reality would parse the design
    tasks = [
      %{name: "Setup project structure", priority: :high, phase: 1},
      %{name: "Implement core features", priority: :high, phase: 2},
      %{name: "Add tests", priority: :medium, phase: 2},
      %{name: "Documentation", priority: :low, phase: 3}
    ]
    {:ok, tasks}
  end

  @impl true
  def sequence_tasks(tasks) do
    # Group by phase and sort by priority
    tasks
    |> Enum.group_by(& &1.phase)
    |> Enum.sort_by(fn {phase, _} -> phase end)
    |> Enum.map(fn {phase, phase_tasks} ->
      %{
        phase: phase,
        tasks: Enum.sort_by(phase_tasks, & &1.priority, :desc)
      }
    end)
  end

  @impl true
  def format_plan(plan, format) do
    case format do
      :json -> Jason.encode!(plan, pretty: true)
      :yaml -> "# YAML output not yet implemented\n" <> inspect(plan)
      _ -> format_as_markdown(plan)
    end
  end

  defp validate_from_option(%{from: from}) when is_binary(from), do: {:ok, from}
  defp validate_from_option(_), do: {:error, ":from option is required"}

  defp handle_output(formatted, %{slice: true, dir: _dir}) do
    # Would call Slicer here
    {:ok, [formatted]}
  end
  defp handle_output(formatted, _options), do: {:ok, formatted}

  defp format_as_markdown(phases) do
    sections = Enum.map(phases, fn %{phase: phase, tasks: tasks} ->
      """
      ## Phase #{phase}
      
      #{format_tasks(tasks)}
      """
    end)
    
    """  
    # Implementation Plan
    
    #{Enum.join(sections, "\n")}
    """
  end

  defp format_tasks(tasks) do
    tasks
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {task, idx} ->
      "#{idx}. #{task.name} (Priority: #{task.priority})"
    end)
  end
end