defmodule SpecforgeCore.Slicer do
  @moduledoc """
  Pure text/markdown splitter used internally by system & plan when --slice is specified.
  Handles splitting documents into phases or sections.
  """

  @type slice_options :: %{
          optional(:output_dir) => String.t(),
          optional(:naming_pattern) => String.t()
        }

  @type slice_result :: {:ok, list({filename :: String.t(), content :: String.t()})} | {:error, term()}

  @doc """
  Slices a document into multiple files based on sections or phases.
  
  ## Options
    * `:output_dir` - Directory to write sliced files
    * `:naming_pattern` - Pattern for naming output files
  """
  @callback slice_document(content :: String.t(), options :: slice_options()) :: slice_result()

  @doc """
  Detects section boundaries in a markdown document.
  Returns a list of {title, content} tuples.
  """
  @callback detect_sections(content :: String.t()) :: list({String.t(), String.t()})

  @doc """
  Generates a filename from a section title using the naming pattern.
  """
  @callback generate_filename(title :: String.t(), index :: integer(), pattern :: String.t()) :: String.t()

  @doc """
  Writes sliced sections to files in the specified directory.
  """
  @callback write_slices(slices :: list({String.t(), String.t()}), output_dir :: String.t()) :: :ok | {:error, term()}
end