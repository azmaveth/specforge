defmodule SpecforgeCore.Impl.TaskPlannerImpl do
  @moduledoc """
  Default implementation of the TaskPlanner behaviour.
  """
  @behaviour SpecforgeCore.TaskPlanner

  alias ExLLM
  
  @impl true
  def analyze_task(task_description, options \\ %{}) do
    with {:ok, validated} <- maybe_validate(task_description, options),
         {:ok, plan} <- generate_plan(validated, options) do
      render_with_template(plan, Map.get(options, :template))
    end
  end

  @impl true
  def validate_task(task_description) do
    # TODO: Implement validation logic
    # For now, just check if the description is not empty
    if String.trim(task_description) == "" do
      {:error, "Task description cannot be empty"}
    else
      {:ok, task_description}
    end
  end

  @impl true
  def render_with_template(plan, nil) do
    # Use default template
    rendered = """
    # Task Plan
    
    ## Overview
    #{Map.get(plan, :overview, "No overview provided")}
    
    ## Steps
    #{format_steps(Map.get(plan, :steps, []))}
    
    ## Considerations
    #{format_considerations(Map.get(plan, :considerations, []))}
    """
    {:ok, rendered}
  end

  def render_with_template(_plan, _template_path) do
    # TODO: Load and render custom template
    {:error, "Custom templates not yet implemented"}
  end

  defp maybe_validate(task_description, %{validate: false}), do: {:ok, task_description}
  defp maybe_validate(task_description, _options), do: validate_task(task_description)

  defp generate_plan(task_description, _options) do
    # TODO: Implement LLM integration
    # For now, return a stub plan
    plan = %{
      overview: "Plan for: #{task_description}",
      steps: [
        "Analyze requirements",
        "Design solution",
        "Implement features",
        "Test implementation"
      ],
      considerations: [
        "Consider edge cases",
        "Ensure scalability"
      ]
    }
    {:ok, plan}
  end

  defp format_steps(steps) do
    steps
    |> Enum.with_index(1)
    |> Enum.map_join("\n", fn {step, idx} -> "#{idx}. #{step}" end)
  end

  defp format_considerations(considerations) do
    Enum.map_join(considerations, "\n", fn c -> "- #{c}" end)
  end
end