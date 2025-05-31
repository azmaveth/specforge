defmodule SpecforgeCore.Impl.TaskPlannerImplTest do
  use ExUnit.Case, async: false
  
  alias SpecforgeCore.Impl.TaskPlannerImpl
  alias SpecforgeCore.Cache

  setup do
    # Clear cache before each test
    Cache.clear()
    :ok
  end

  describe "analyze_task/2" do
    test "analyzes task successfully with validation" do
      task = "Build a user authentication system"
      
      {:ok, result} = TaskPlannerImpl.analyze_task(task, %{model: :mock})
      
      assert is_binary(result)
      assert result =~ "# Task Plan"
      assert result =~ "## Overview"
      assert result =~ "## Implementation Steps"
      assert result =~ "## Important Considerations"
    end

    test "returns error for empty task description" do
      assert {:error, "Task description cannot be empty"} = 
        TaskPlannerImpl.analyze_task("")
      
      assert {:error, "Task description cannot be empty"} = 
        TaskPlannerImpl.analyze_task("   ")
    end

    test "skips validation when validate: false option is passed" do
      # Even empty string should pass when validation is disabled
      {:ok, result} = TaskPlannerImpl.analyze_task("", %{validate: false, model: :mock})
      
      assert is_binary(result)
      assert result =~ "# Task Plan"
    end

    test "uses cache by default" do
      task = "Create a REST API"
      
      # First call should generate new plan
      {:ok, result1} = TaskPlannerImpl.analyze_task(task, %{model: :mock})
      
      # Second call should return cached result
      {:ok, result2} = TaskPlannerImpl.analyze_task(task, %{model: :mock})
      
      assert result1 == result2
    end

    test "skips cache when cache: false option is passed" do
      task = "Create a REST API"
      
      # Generate initial result
      {:ok, _result1} = TaskPlannerImpl.analyze_task(task, %{model: :mock})
      
      # Call with cache: false should generate new plan
      # (In real implementation with LLM, this might return different result)
      {:ok, result2} = TaskPlannerImpl.analyze_task(task, %{cache: false, model: :mock})
      
      assert is_binary(result2)
    end

    test "returns error when custom template is requested" do
      task = "Build a feature"
      
      assert {:error, "Custom templates not yet implemented"} = 
        TaskPlannerImpl.analyze_task(task, %{template: "custom.eex", model: :mock})
    end
  end

  describe "validate_task/1" do
    test "validates non-empty task descriptions" do
      assert {:ok, "Build a feature"} = TaskPlannerImpl.validate_task("Build a feature")
      assert {:ok, "x"} = TaskPlannerImpl.validate_task("x")
    end

    test "returns error for empty task descriptions" do
      assert {:error, "Task description cannot be empty"} = 
        TaskPlannerImpl.validate_task("")
      
      assert {:error, "Task description cannot be empty"} = 
        TaskPlannerImpl.validate_task("   ")
      
      assert {:error, "Task description cannot be empty"} = 
        TaskPlannerImpl.validate_task("\n\t")
    end
  end

  describe "render_with_template/2" do
    test "renders plan with default template when template is nil" do
      plan = %{
        overview: "Build a comprehensive user authentication system",
        steps: [
          "Design database schema",
          "Implement user registration",
          "Add login functionality",
          "Create password reset flow"
        ],
        considerations: [
          "Use bcrypt for password hashing",
          "Implement rate limiting",
          "Add CSRF protection"
        ]
      }
      
      {:ok, rendered} = TaskPlannerImpl.render_with_template(plan, nil)
      
      assert rendered =~ "# Task Plan"
      assert rendered =~ "## Overview"
      assert rendered =~ "Build a comprehensive user authentication system"
      assert rendered =~ "## Implementation Steps"
      assert rendered =~ "1. Design database schema"
      assert rendered =~ "2. Implement user registration"
      assert rendered =~ "3. Add login functionality"
      assert rendered =~ "4. Create password reset flow"
      assert rendered =~ "## Important Considerations"
      assert rendered =~ "**Complexity:**"
      assert rendered =~ "**Estimated Time:**"
      assert rendered =~ "- Use bcrypt for password hashing"
      assert rendered =~ "- Implement rate limiting"
      assert rendered =~ "- Add CSRF protection"
    end

    test "handles missing fields gracefully" do
      plan = %{}
      
      {:ok, rendered} = TaskPlannerImpl.render_with_template(plan, nil)
      
      assert rendered =~ "No overview provided"
      assert rendered =~ "## Implementation Steps\n\n"  # Empty steps section
      assert rendered =~ "## Important Considerations\n"  # Empty considerations section
    end

    test "returns error for custom templates" do
      plan = %{overview: "Test"}
      
      assert {:error, "Custom templates not yet implemented"} = 
        TaskPlannerImpl.render_with_template(plan, "custom.eex")
    end
  end
end