defmodule SpecForgeWebWeb.Api.SystemController do
  use SpecForgeWebWeb, :controller
  
  alias SpecforgeCore.Impl.SystemDesignerImpl
  
  action_fallback SpecForgeWebWeb.Api.FallbackController

  @doc """
  POST /api/system
  Creates or refines a system design.
  """
  def create(conn, params) do
    with {:ok, validated_params} <- validate_system_params(params),
         {:ok, job_id} <- start_async_system_design(validated_params) do
      conn
      |> put_status(:accepted)
      |> json(%{
        job_id: job_id,
        status: "processing",
        message: "System design started"
      })
    end
  end

  defp validate_system_params(params) do
    cond do
      params["interactive"] == true ->
        {:ok, %{interactive: true}}
      
      is_binary(params["from"]) ->
        {:ok, %{from: params["from"]}}
      
      true ->
        {:error, :bad_request, "Must specify either 'interactive' or 'from' parameter"}
    end
  end

  defp start_async_system_design(validated_params) do
    job_id = generate_job_id()
    
    :ets.insert(:specforge_jobs, {job_id, %{
      type: :system,
      status: :processing,
      params: validated_params,
      started_at: DateTime.utc_now()
    }})
    
    Task.start(fn ->
      process_system_design(job_id, validated_params)
    end)
    
    {:ok, job_id}
  end

  defp process_system_design(job_id, params) do
    # Stub implementation
    result = %{
      status: :completed,
      result: %{
        title: "System Design",
        message: "System design feature not yet implemented",
        params: params
      }
    }
    
    :ets.update_element(:specforge_jobs, job_id, {2, Map.merge(result, %{
      completed_at: DateTime.utc_now()
    })})
  end

  defp generate_job_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end