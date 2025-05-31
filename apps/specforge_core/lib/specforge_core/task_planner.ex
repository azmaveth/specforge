defmodule SpecforgeCore.TaskPlanner do
  @moduledoc """
  Implements the 'spec task' verb: validate → LLM → template → file.
  Analyzes any task description and returns an actionable plan.
  """

  @type task_options :: %{
          optional(:model) => String.t(),
          optional(:search) => boolean(),
          optional(:template) => String.t(),
          optional(:validate) => boolean(),
          optional(:cache) => boolean()
        }

  @type task_result :: {:ok, String.t()} | {:error, term()}

  @doc """
  Analyzes a task description and generates an actionable plan.
  
  ## Options
    * `:model` - LLM model to use (e.g., "openai:gpt-4o")
    * `:search` - Whether to augment with web context
    * `:template` - Custom template file path
    * `:validate` - Whether to validate the task description
    * `:cache` - Whether to use caching
  """
  @callback analyze_task(task_description :: String.t(), options :: task_options()) :: task_result()

  @doc """
  Validates a task description for clarity and completeness.
  """
  @callback validate_task(task_description :: String.t()) :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Renders the task plan using the specified template.
  """
  @callback render_with_template(plan :: map(), template_path :: String.t() | nil) :: {:ok, String.t()} | {:error, term()}
end