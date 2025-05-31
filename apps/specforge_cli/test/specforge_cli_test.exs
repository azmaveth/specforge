defmodule SpecforgeCliTest do
  use ExUnit.Case
  doctest SpecforgeCli

  test "greets the world" do
    assert SpecforgeCli.hello() == :world
  end
end
