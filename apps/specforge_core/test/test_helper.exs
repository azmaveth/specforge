ExUnit.start()

# Define mocks for testing
Mox.defmock(SpecforgeCore.MockTaskPlanner, for: SpecforgeCore.TaskPlanner)
Mox.defmock(SpecforgeCore.MockSystemDesigner, for: SpecforgeCore.SystemDesigner)
Mox.defmock(SpecforgeCore.MockPlanGenerator, for: SpecforgeCore.PlanGenerator)
Mox.defmock(SpecforgeCore.MockSlicer, for: SpecforgeCore.Slicer)

# Mock for ExLLM
Mox.defmock(ExLLM.MockAdapter, for: ExLLM.Adapter)
