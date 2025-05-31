defmodule SpecforgeCore.PropertyTest do
  use ExUnit.Case
  use ExUnitProperties
  
  alias SpecforgeCore.Impl.SlicerImpl
  
  describe "Slicer property tests" do
    property "detect_sections always returns a list of tuples" do
      check all content <- string(:printable) do
        result = SlicerImpl.detect_sections(content)
        assert is_list(result)
        assert Enum.all?(result, fn item ->
          match?({title, section_content} when is_binary(title) and is_binary(section_content), item)
        end)
      end
    end
    
    property "generate_filename produces valid filenames" do
      check all title <- string(:alphanumeric, min_length: 1),
                index <- integer(0..99),
                pattern <- string(:alphanumeric, min_length: 1) do
        filename = SlicerImpl.generate_filename(title, index, pattern)
        assert is_binary(filename)
        assert filename =~ ~r/\.md$/
        # Filename should contain the pattern
        assert filename =~ pattern
        # Should not contain invalid characters
        refute filename =~ ~r/[<>:"|?*]/
      end
    end
    
    property "slice_document preserves content" do
      check all sections <- list_of(tuple({string(:alphanumeric), string(:printable)}), min_length: 1) do
        # Build a markdown document from sections
        content = Enum.map_join(sections, "\n\n", fn {title, body} ->
          "## #{title}\n#{body}"
        end)
        
        {:ok, slices} = SlicerImpl.slice_document(content, %{})
        
        # The number of slices should match the number of sections
        assert length(slices) == length(sections)
        
        # All content should be preserved (though formatting might change)
        Enum.each(sections, fn {_title, body} ->
          assert Enum.any?(slices, fn {_filename, slice_content} ->
            String.contains?(slice_content, body)
          end)
        end)
      end
    end
  end
  
  describe "TaskPlanner property tests" do
    property "validate_task handles all string inputs safely" do
      check all input <- string(:printable) do
        result = SpecforgeCore.Impl.TaskPlannerImpl.validate_task(input)
        assert match?({:ok, _}, result) or match?({:error, _}, result)
        
        # Non-empty strings should be valid
        if String.trim(input) != "" do
          assert {:ok, ^input} = result
        else
          assert {:error, _} = result
        end
      end
    end
  end
end