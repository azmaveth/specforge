defmodule SpecforgeCore.CacheTest do
  use ExUnit.Case, async: false
  
  alias SpecforgeCore.Cache
  
  setup do
    # Clear cache before each test
    Cache.clear()
    :ok
  end
  
  describe "get/1 and put/3" do
    test "stores and retrieves values" do
      key = "test_key"
      value = %{data: "test value"}
      
      # Initially not found
      assert {:error, :not_found} = Cache.get(key)
      
      # Put value
      assert :ok = Cache.put(key, value)
      
      # Now it should be found
      assert {:ok, ^value} = Cache.get(key)
    end
    
    test "respects TTL" do
      key = "ttl_test"
      value = "short lived"
      
      # Put with very short TTL
      assert :ok = Cache.put(key, value, ttl: 10)  # 10ms
      
      # Should be found immediately
      assert {:ok, ^value} = Cache.get(key)
      
      # Wait for expiration
      Process.sleep(20)
      
      # Should be expired
      assert {:error, :not_found} = Cache.get(key)
    end
  end
  
  describe "fetch/3" do
    test "returns cached value if present" do
      key = "fetch_test"
      cached_value = "cached"
      
      # Pre-populate cache
      Cache.put(key, cached_value)
      
      # Fetch should return cached value without calling function
      result = Cache.fetch(key, fn ->
        # This should not be called
        flunk("Function should not be called when value is cached")
      end)
      
      assert {:ok, ^cached_value} = result
    end
    
    test "calls function and caches result when not found" do
      key = "fetch_new"
      new_value = "generated"
      
      # Ensure not in cache
      assert {:error, :not_found} = Cache.get(key)
      
      # Fetch should call function
      result = Cache.fetch(key, fn ->
        {:ok, new_value}
      end)
      
      assert {:ok, ^new_value} = result
      
      # Value should now be cached
      assert {:ok, ^new_value} = Cache.get(key)
    end
    
    test "propagates function errors without caching" do
      key = "fetch_error"
      
      # Fetch with failing function
      result = Cache.fetch(key, fn ->
        {:error, "something went wrong"}
      end)
      
      assert {:error, "something went wrong"} = result
      
      # Nothing should be cached
      assert {:error, :not_found} = Cache.get(key)
    end
    
    test "respects TTL options" do
      key = "fetch_ttl"
      value = "ttl_value"
      
      # Fetch with custom TTL
      Cache.fetch(key, fn -> {:ok, value} end, ttl: 10)
      
      # Should be found immediately
      assert {:ok, ^value} = Cache.get(key)
      
      # Wait for expiration
      Process.sleep(20)
      
      # Should be expired
      assert {:error, :not_found} = Cache.get(key)
    end
  end
  
  describe "delete/1" do
    test "removes entries from cache" do
      key = "delete_test"
      value = "to be deleted"
      
      # Add to cache
      Cache.put(key, value)
      assert {:ok, ^value} = Cache.get(key)
      
      # Delete
      assert {:ok, true} = Cache.delete(key)
      
      # Should be gone
      assert {:error, :not_found} = Cache.get(key)
    end
  end
  
  describe "clear/0" do
    test "removes all entries" do
      # Add multiple entries
      Cache.put("key1", "value1")
      Cache.put("key2", "value2")
      Cache.put("key3", "value3")
      
      # Verify they exist
      assert {:ok, "value1"} = Cache.get("key1")
      assert {:ok, "value2"} = Cache.get("key2")
      assert {:ok, "value3"} = Cache.get("key3")
      
      # Clear all
      assert {:ok, 3} = Cache.clear()
      
      # All should be gone
      assert {:error, :not_found} = Cache.get("key1")
      assert {:error, :not_found} = Cache.get("key2")
      assert {:error, :not_found} = Cache.get("key3")
    end
  end
  
  describe "generate_key/2" do
    test "generates consistent keys for same input" do
      operation = :task_plan
      params = %{task: "build API", options: %{cache: true}}
      
      key1 = Cache.generate_key(operation, params)
      key2 = Cache.generate_key(operation, params)
      
      assert key1 == key2
      assert is_binary(key1)
    end
    
    test "generates different keys for different inputs" do
      key1 = Cache.generate_key(:task_plan, %{task: "build API"})
      key2 = Cache.generate_key(:task_plan, %{task: "build UI"})
      key3 = Cache.generate_key(:system_design, %{task: "build API"})
      
      assert key1 != key2
      assert key1 != key3
      assert key2 != key3
    end
  end
  
  describe "stats/0" do
    test "returns cache statistics" do
      # Add some entries
      Cache.put("stat1", "value1")
      Cache.put("stat2", "value2")
      
      # Get one to create a hit
      Cache.get("stat1")
      # Get non-existent to create a miss
      Cache.get("nonexistent")
      
      {:ok, stats} = Cache.stats()
      
      assert is_map(stats)
      # Stats structure may vary, but should at least have some fields
      assert Map.has_key?(stats, :hits) or Map.has_key?(stats, :misses) or Map.has_key?(stats, :operations)
    end
  end
end