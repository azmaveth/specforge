defmodule SpecforgeCore.TestCase do
  @moduledoc """
  Base test case for SpecforgeCore tests.
  
  Provides common test functionality and helpers.
  """
  
  use ExUnit.CaseTemplate
  
  using do
    quote do
      import Mox
      import SpecforgeCore.TestCase
      
      # Make sure mocks are verified on exit
      setup :verify_on_exit!
    end
  end
  
  @doc """
  Creates a temporary directory for testing file operations.
  """
  def with_tmp_dir(fun) do
    tmp_dir = Path.join(System.tmp_dir!(), "specforge_test_#{:rand.uniform(1_000_000)}")
    File.mkdir_p!(tmp_dir)
    
    try do
      fun.(tmp_dir)
    after
      File.rm_rf!(tmp_dir)
    end
  end
  
  @doc """
  Helper to create test files in a directory.
  """
  def create_test_file(dir, filename, content) do
    path = Path.join(dir, filename)
    File.write!(path, content)
    path
  end
  
  @doc """
  Stub LLM response for testing.
  """
  def stub_llm_response(response) do
    # This would integrate with ExLLM mocking
    # For now, just return the response
    response
  end
end