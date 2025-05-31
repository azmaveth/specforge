defmodule SpecforgeCore.Impl.SystemDesignerImpl do
  @moduledoc """
  Default implementation of the SystemDesigner behaviour.
  """
  @behaviour SpecforgeCore.SystemDesigner

  @impl true
  def design_system(options \\ %{}) do
    cond do
      Map.get(options, :interactive) -> interactive_design_flow(options)
      Map.get(options, :from) -> refine_existing_design(options)
      true -> {:error, "Must specify either :interactive or :from option"}
    end
  end

  @impl true
  def interactive_design() do
    # Stub implementation for interactive design
    design = %{
      title: "System Design",
      overview: "Interactive system design",
      components: [],
      architecture: %{},
      requirements: []
    }
    {:ok, design}
  end

  @impl true
  def prompt_extract_phases() do
    # In real implementation, would use Owl to prompt user
    true
  end

  @impl true
  def format_output(design, format) do
    case format do
      :json -> Jason.encode!(design, pretty: true)
      :yaml -> "# YAML output not yet implemented\n" <> inspect(design)
      _ -> format_as_markdown(design)
    end
  end

  defp interactive_design_flow(options) do
    with {:ok, design} <- interactive_design(),
         formatted <- format_output(design, Map.get(options, :format, :md)) do
      {:ok, formatted}
    end
  end

  defp refine_existing_design(_options) do
    # Stub implementation
    {:error, "Refining existing designs not yet implemented"}
  end

  defp format_as_markdown(design) do
    """
    # #{Map.get(design, :title, "System Design")}
    
    ## Overview
    #{Map.get(design, :overview, "No overview provided")}
    
    ## Components
    #{format_components(Map.get(design, :components, []))}
    
    ## Requirements
    #{format_requirements(Map.get(design, :requirements, []))}
    """
  end

  defp format_components([]), do: "No components defined yet."
  defp format_components(components) do
    Enum.map_join(components, "\n", fn comp -> "- #{comp}" end)
  end

  defp format_requirements([]), do: "No requirements defined yet."
  defp format_requirements(requirements) do
    Enum.map_join(requirements, "\n", fn req -> "- #{req}" end)
  end
end