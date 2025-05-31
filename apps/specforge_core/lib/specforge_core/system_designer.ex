defmodule SpecforgeCore.SystemDesigner do
  @moduledoc """
  Implements the 'spec system' verb for creating or refining system designs.
  Supports both interactive and file-based modes.
  """

  @type system_options :: %{
          optional(:from) => String.t(),
          optional(:interactive) => boolean(),
          optional(:format) => :md | :json | :yaml,
          optional(:conventions) => String.t(),
          optional(:deep_task) => boolean(),
          optional(:model) => String.t(),
          optional(:cache) => boolean()
        }

  @type system_result :: {:ok, String.t()} | {:error, term()}

  @doc """
  Creates or refines a system design.
  
  ## Options
    * `:from` - Existing design document path
    * `:interactive` - Whether to use guided interview mode
    * `:format` - Output format (:md, :json, :yaml)
    * `:conventions` - Path to team style guide
    * `:deep_task` - Whether to run spec plan on every subtask
    * `:model` - LLM model to use
    * `:cache` - Whether to use caching
  """
  @callback design_system(options :: system_options()) :: system_result()

  @doc """
  Runs an interactive design session, collecting user input through prompts.
  """
  @callback interactive_design() :: {:ok, map()} | {:error, term()}

  @doc """
  Prompts user whether to extract phases from the design.
  """
  @callback prompt_extract_phases() :: boolean()

  @doc """
  Formats the design output according to the specified format.
  """
  @callback format_output(design :: map(), format :: :md | :json | :yaml) :: String.t()
end