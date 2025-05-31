defmodule SpecforgeCore.Impl.SystemDesignerImplTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  
  alias SpecforgeCore.Impl.SystemDesignerImpl
  
  describe "interactive_design/0" do
    test "completes full interactive flow successfully" do
      input = """
      My Awesome System
      A system that does awesome things


      Must be scalable
      Should handle 1000 requests per second

      Web API
      Database
      Cache

      Microservices with event-driven communication


      """
      
      output = capture_io([input: input, capture_prompt: false], fn ->
        result = SystemDesignerImpl.interactive_design()
        send(self(), {:result, result})
      end)
      
      assert_received {:result, {:ok, design}}
      
      # Verify the design has all expected fields
      assert design.title == "My Awesome System"
      assert design.overview == "A system that does awesome things"
      assert design.requirements == ["Must be scalable", "Should handle 1000 requests per second"]
      assert design.components == ["Web API", "Database", "Cache"]
      assert design.architecture == %{description: "Microservices with event-driven communication", patterns: []}
      
      # Verify output contains expected prompts
      assert output =~ "Welcome to SpecForge System Design Interactive Mode"
      assert output =~ "What is the title of your system?"
      assert output =~ "Provide a brief description"
      assert output =~ "Enter system requirements"
      assert output =~ "Enter major system components"
      assert output =~ "Describe the architecture"
    end
    
    test "handles user cancellation at title prompt" do
      input = "\n"  # Empty input cancels
      
      _output = capture_io([input: input, capture_prompt: false], fn ->
        result = SystemDesignerImpl.interactive_design()
        send(self(), {:result, result})
      end)
      
      assert_received {:result, {:error, "Title cannot be empty"}}
    end
    
    test "completes successfully with minimal input" do
      input = """
      Test System
      Test description


      First requirement

      Component 1

      Architecture desc


      """
      
      _output = capture_io([input: input, capture_prompt: false], fn ->
        result = SystemDesignerImpl.interactive_design()
        send(self(), {:result, result})
      end)
      
      assert_received {:result, {:ok, design}}
      assert design.title == "Test System"
      assert design.overview == "Test description"
      assert design.requirements == ["First requirement"]
      assert design.components == ["Component 1"]
      assert design.architecture == %{description: "Architecture desc", patterns: []}
    end
  end
  
  describe "design_from_spec/1" do
    test "creates design from complete spec" do
      spec = %{
        title: "E-commerce Platform",
        description: "A scalable e-commerce platform",
        requirements: [
          "Handle 10k concurrent users",
          "Process payments securely",
          "Support multiple currencies"
        ],
        components: [
          "Web Frontend",
          "API Gateway", 
          "Payment Service",
          "Inventory Service",
          "Database Cluster"
        ],
        architecture: "Microservices with API Gateway pattern"
      }
      
      {:ok, design} = SystemDesignerImpl.design_from_spec(spec)
      
      assert design.title == spec.title
      assert design.description == spec.description
      assert design.requirements == spec.requirements
      assert design.components == spec.components
      assert design.architecture == spec.architecture
      assert design.created_at != nil
      assert design.version == "1.0.0"
    end
    
    test "returns error for missing title" do
      spec = %{
        description: "A system",
        requirements: ["Requirement 1"],
        components: ["Component 1"],
        architecture: "Simple"
      }
      
      assert {:error, "Missing required field: title"} = 
        SystemDesignerImpl.design_from_spec(spec)
    end
    
    test "returns error for empty requirements" do
      spec = %{
        title: "System",
        description: "A system",
        requirements: [],
        components: ["Component 1"],
        architecture: "Simple"
      }
      
      assert {:error, "Requirements cannot be empty"} = 
        SystemDesignerImpl.design_from_spec(spec)
    end
  end
  
  describe "validate_design/1" do
    test "validates complete design" do
      design = %{
        title: "Valid System",
        description: "A valid system design",
        requirements: ["Req 1", "Req 2"],
        components: ["Comp 1", "Comp 2"],
        architecture: "Layered architecture",
        created_at: DateTime.utc_now(),
        version: "1.0.0"
      }
      
      assert {:ok, ^design} = SystemDesignerImpl.validate_design(design)
    end
    
    test "returns error for missing fields" do
      design = %{
        title: "Incomplete"
      }
      
      {:error, errors} = SystemDesignerImpl.validate_design(design)
      
      assert is_list(errors)
      assert "Missing description" in errors
      assert "Missing requirements" in errors
      assert "Missing components" in errors
      assert "Missing architecture" in errors
    end
    
    test "returns error for invalid types" do
      design = %{
        title: 123,  # Should be string
        description: "Valid",
        requirements: "Should be list",  # Should be list
        components: ["Valid"],
        architecture: "Valid"
      }
      
      {:error, errors} = SystemDesignerImpl.validate_design(design)
      
      assert is_list(errors)
      assert Enum.any?(errors, &String.contains?(&1, "title"))
      assert Enum.any?(errors, &String.contains?(&1, "requirements"))
    end
  end
  
  describe "export_as_json/1" do
    test "exports design as JSON" do
      design = %{
        title: "JSON Export Test",
        description: "Testing JSON export",
        requirements: ["Req 1"],
        components: ["Comp 1"],
        architecture: "Simple",
        created_at: ~U[2024-01-01 12:00:00Z],
        version: "1.0.0"
      }
      
      {:ok, json} = SystemDesignerImpl.export_as_json(design)
      
      # Verify it's valid JSON
      {:ok, decoded} = Jason.decode(json)
      
      assert decoded["title"] == "JSON Export Test"
      assert decoded["description"] == "Testing JSON export"
      assert decoded["requirements"] == ["Req 1"]
      assert decoded["components"] == ["Comp 1"]
      assert decoded["architecture"] == "Simple"
      assert decoded["version"] == "1.0.0"
      assert decoded["created_at"] == "2024-01-01T12:00:00Z"
    end
    
    test "handles encoding errors gracefully" do
      # Create a design with a function (which can't be JSON encoded)
      design = %{
        title: "Bad Design",
        bad_field: fn -> :error end
      }
      
      assert {:error, _reason} = SystemDesignerImpl.export_as_json(design)
    end
  end
end