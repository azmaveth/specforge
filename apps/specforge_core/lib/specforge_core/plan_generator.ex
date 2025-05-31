defmodule SpecforgeCore.PlanGenerator do
  @moduledoc """
  Converts an existing system design into a sequenced implementation plan.
  This is what the former --deep-task flag did, now as a first-class verb.
  """

  @type plan_options :: %{
          required(:from) => String.t(),
          optional(:model) => String.t(),
          optional(:format) => :md | :json | :yaml,
          optional(:slice) => boolean(),
          optional(:dir) => String.t()
        }

  @type plan_result :: {:ok, String.t() | list(String.t())} | {:error, term()}

  @doc """
  Converts a system design into implementation tasks and phases.
  
  ## Options
    * `:from` - Path to the design document (required)
    * `:model` - LLM model to use
    * `:format` - Output format (:md, :json, :yaml)
    * `:slice` - Whether to additionally slice phases into separate files
    * `:dir` - Output directory for sliced files
  """
  @callback generate_plan(options :: plan_options()) :: plan_result()

  @doc """
  Parses a design document and extracts implementable tasks.
  """
  @callback extract_tasks(design_content :: String.t()) :: {:ok, list(map())} | {:error, term()}

  @doc """
  Sequences tasks into phases based on dependencies and complexity.
  """
  @callback sequence_tasks(tasks :: list(map())) :: list(map())

  @doc """
  Formats the plan output according to the specified format.
  """
  @callback format_plan(plan :: list(map()), format :: :md | :json | :yaml) :: String.t()
end