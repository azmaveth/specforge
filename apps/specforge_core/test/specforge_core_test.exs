defmodule SpecforgeCoreTest do
  use ExUnit.Case
  doctest SpecforgeCore

  test "greets the world" do
    assert SpecforgeCore.hello() == :world
  end
end
