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
    IO.puts("\n🏗️  Welcome to SpecForge System Design Interactive Mode\n")
    
    with {:ok, title} <- prompt_for_title(),
         {:ok, description} <- prompt_for_description(),
         {:ok, requirements} <- prompt_for_requirements(),
         {:ok, components} <- prompt_for_components(),
         {:ok, architecture} <- prompt_for_architecture() do
      
      design = %{
        title: title,
        overview: description,
        requirements: requirements,
        components: components,
        architecture: architecture,
        timestamp: DateTime.utc_now()
      }
      
      {:ok, design}
    end
  end

  @impl true
  def prompt_extract_phases() do
    case prompt_yes_no("Would you like to extract phases into separate files?") do
      {:ok, answer} -> answer
      {:error, _} -> false
    end
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

  # Interactive prompting helpers
  defp prompt_for_title do
    IO.puts("📝 What is the title of your system?")
    case IO.gets("> ") |> String.trim() do
      "" -> {:error, "Title cannot be empty"}
      title -> {:ok, title}
    end
  end

  defp prompt_for_description do
    IO.puts("\n📋 Provide a brief description of the system:")
    IO.puts("(Press Enter twice when done)")
    
    description = read_multiline_input()
    if String.trim(description) == "" do
      {:error, "Description cannot be empty"}
    else
      {:ok, description}
    end
  end

  defp prompt_for_requirements do
    IO.puts("\n📌 Enter system requirements (one per line, empty line to finish):")
    requirements = collect_list_input()
    {:ok, requirements}
  end

  defp prompt_for_components do
    IO.puts("\n🧩 Enter major system components (one per line, empty line to finish):")
    components = collect_list_input()
    {:ok, components}
  end

  defp prompt_for_architecture do
    IO.puts("\n🏛️  Describe the architecture patterns and key decisions:")
    IO.puts("(Press Enter twice when done)")
    
    arch_description = read_multiline_input()
    {:ok, %{description: arch_description, patterns: []}}
  end

  defp prompt_yes_no(question) do
    IO.puts("\n❓ #{question} (y/n)")
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

  defp read_multiline_input do
    read_multiline_input([])
  end

  defp read_multiline_input(lines) do
    case IO.gets("") do
      :eof -> lines |> Enum.reverse() |> Enum.join("\n")
      {:error, _} -> lines |> Enum.reverse() |> Enum.join("\n")
      line ->
        line = String.trim_trailing(line, "\n")
        if line == "" and List.first(lines) == "" do
          lines |> tl() |> Enum.reverse() |> Enum.join("\n")
        else
          read_multiline_input([line | lines])
        end
    end
  end

  defp collect_list_input do
    collect_list_input([])
  end

  defp collect_list_input(items) do
    case IO.gets("- ") do
      :eof -> Enum.reverse(items)
      {:error, _} -> Enum.reverse(items)
      line ->
        case String.trim(line) do
          "" -> Enum.reverse(items)
          item -> collect_list_input([item | items])
        end
    end
  end

  # Public API functions for testing
  
  def design_from_spec(spec) do
    required_fields = [:title, :description, :requirements, :components, :architecture]
    
    with :ok <- validate_spec_fields(spec, required_fields),
         :ok <- validate_requirements(spec) do
      design = Map.merge(spec, %{
        created_at: DateTime.utc_now(),
        version: "1.0.0"
      })
      {:ok, design}
    end
  end
  
  def validate_design(design) do
    errors = []
    
    errors = if Map.has_key?(design, :title) do
      if is_binary(design.title) do
        errors
      else
        ["Invalid title type" | errors]
      end
    else
      ["Missing title" | errors]
    end
    
    errors = if Map.has_key?(design, :description), do: errors, else: ["Missing description" | errors]
    
    errors = if Map.has_key?(design, :requirements) do
      if is_list(design.requirements) do
        errors
      else
        ["Invalid requirements type" | errors]
      end
    else
      ["Missing requirements" | errors]
    end
    
    errors = if Map.has_key?(design, :components), do: errors, else: ["Missing components" | errors]
    errors = if Map.has_key?(design, :architecture), do: errors, else: ["Missing architecture" | errors]
    
    if errors == [] do
      {:ok, design}
    else
      {:error, Enum.reverse(errors)}
    end
  end
  
  def export_as_json(design) do
    case Jason.encode(design, pretty: true) do
      {:ok, json} -> {:ok, json}
      {:error, _} = error -> error
    end
  end
  
  defp validate_spec_fields(spec, required_fields) do
    missing = Enum.find(required_fields, fn field ->
      not Map.has_key?(spec, field)
    end)
    
    if missing do
      {:error, "Missing required field: #{missing}"}
    else
      :ok
    end
  end
  
  defp validate_requirements(%{requirements: []}) do
    {:error, "Requirements cannot be empty"}
  end
  defp validate_requirements(_), do: :ok
end