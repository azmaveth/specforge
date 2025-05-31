defmodule SpecforgeCore.Impl.SlicerImpl do
  @moduledoc """
  Default implementation of the Slicer behaviour.
  Handles splitting documents into phases or sections.
  """
  @behaviour SpecforgeCore.Slicer

  @impl true
  def slice_document(content, options \\ %{}) do
    sections = detect_sections(content)
    
    case Map.get(options, :output_dir) do
      nil -> 
        # Return sections without writing
        {:ok, Enum.map(sections, fn {title, content} -> 
          {generate_filename(title, 0, "section"), content}
        end)}
      dir -> 
        # Write sections to files
        write_slices(sections, dir)
    end
  end

  @impl true
  def detect_sections(content) do
    # Simple markdown header detection
    lines = String.split(content, "\n")
    
    lines
    |> Enum.reduce({[], nil, []}, fn line, {sections, current_title, current_content} ->
      cond do
        String.starts_with?(line, "## ") ->
          # New section header
          new_title = String.trim_leading(line, "## ")
          updated_sections = if current_title do
            [{current_title, Enum.reverse(current_content) |> Enum.join("\n")} | sections]
          else
            sections
          end
          {updated_sections, new_title, []}
        
        String.starts_with?(line, "# ") and is_nil(current_title) ->
          # Document title, not a section
          {sections, current_title, [line | current_content]}
          
        true ->
          # Regular content
          {sections, current_title, [line | current_content]}
      end
    end)
    |> then(fn {sections, last_title, last_content} ->
      if last_title do
        [{last_title, Enum.reverse(last_content) |> Enum.join("\n")} | sections]
      else
        sections
      end
    end)
    |> Enum.reverse()
  end

  @impl true
  def generate_filename(title, index, pattern \\ "section") do
    slug = title
           |> String.downcase()
           |> String.replace(~r/[^a-z0-9]+/, "_")
           |> String.trim("_")
    
    "#{pattern}_#{String.pad_leading(Integer.to_string(index + 1), 2, "0")}_#{slug}.md"
  end

  @impl true
  def write_slices(slices, output_dir) do
    # Ensure directory exists
    File.mkdir_p!(output_dir)
    
    results = slices
              |> Enum.with_index()
              |> Enum.map(fn {{title, content}, index} ->
                filename = generate_filename(title, index)
                path = Path.join(output_dir, filename)
                
                case File.write(path, content) do
                  :ok -> {filename, content}
                  {:error, reason} -> {:error, {filename, reason}}
                end
              end)
    
    errors = Enum.filter(results, &match?({:error, _}, &1))
    
    if Enum.empty?(errors) do
      {:ok, Enum.filter(results, &match?({_, _}, &1))}
    else
      {:error, errors}
    end
  end
end