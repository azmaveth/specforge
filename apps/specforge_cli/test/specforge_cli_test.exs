defmodule SpecforgeCliTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  
  describe "main/1" do
    test "shows help when no arguments provided" do
      output = capture_io(fn ->
        try do
          SpecforgeCli.main([])
        catch
          :exit, _ -> :ok
        end
      end)
      
      assert output =~ "SpecForge"
      assert output =~ "Next-Generation Task & Design Spec Assistant"
      assert output =~ "Commands:"
      assert output =~ "task"
      assert output =~ "system"
      assert output =~ "plan"
    end
    
    test "shows version with --version flag" do
      output = capture_io(fn ->
        SpecforgeCli.main(["--version"])
      end)
      
      assert output =~ "SpecForge v"
    end
    
    test "shows help with --help flag" do
      output = capture_io(fn ->
        SpecforgeCli.main(["--help"])
      end)
      
      assert output =~ "SpecForge"
      assert output =~ "Usage:"
    end
    
    test "shows error for unknown command" do
      output = capture_io(fn ->
        try do
          SpecforgeCli.main(["unknown"])
        catch
          :exit, _ -> :ok
        end
      end)
      
      assert output =~ "Unknown command: unknown"
    end
    
    test "shows task help with 'task --help'" do
      output = capture_io(fn ->
        SpecforgeCli.main(["task", "--help"])
      end)
      
      assert output =~ "spec task"
      assert output =~ "Analyze a task"
    end
  end
end