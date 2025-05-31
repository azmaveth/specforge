defmodule SpecForgeWebWeb.Api.PlanController do
  use SpecForgeWebWeb, :controller
  
  alias SpecforgeCore.Impl.PlanGeneratorImpl
  
  action_fallback SpecForgeWebWeb.Api.FallbackController

  @doc """
  POST /api/plan
  Converts a system design into implementation tasks.
  """
  def create(conn, params) do
    with {:ok, from_path} <- validate_plan_params(params),
         {:ok, job_id} <- start_async_plan_generation(from_path, params) do
      conn
      |> put_status(:accepted)
      |> json(%{
        job_id: job_id,
        status: "processing",
        message: "Plan generation started"
      })
    end
  end

  defp validate_plan_params(%{"from" => from}) when is_binary(from) do
    {:ok, from}
  end
  defp validate_plan_params(_), do: {:error, :bad_request, "Missing required 'from' parameter"}

  defp start_async_plan_generation(from_path, params) do
    job_id = generate_job_id()
    
    :ets.insert(:specforge_jobs, {job_id, %{
      type: :plan,
      status: :processing,
      params: params,
      started_at: DateTime.utc_now()
    }})
    
    Task.start(fn ->
      process_plan_generation(job_id, from_path, params)
    end)
    
    {:ok, job_id}
  end

  defp process_plan_generation(job_id, from_path, params) do
    options = build_options(params)
    
    result = case PlanGeneratorImpl.generate_plan(Map.put(options, :from, from_path)) do
      {:ok, plan} -> 
        %{status: :completed, result: plan}
      {:error, reason} -> 
        %{status: :failed, error: inspect(reason)}
    end
    
    :ets.update_element(:specforge_jobs, job_id, {2, Map.merge(result, %{
      completed_at: DateTime.utc_now()
    })})
  end

  defp build_options(params) do
    %{}
    |> maybe_add_option(:model, params["model"])
    |> maybe_add_option(:format, params["format"])
    |> maybe_add_option(:slice, params["slice"] == true)
    |> maybe_add_option(:dir, params["dir"])
  end

  defp maybe_add_option(opts, _key, nil), do: opts
  defp maybe_add_option(opts, key, value), do: Map.put(opts, key, value)

  defp generate_job_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end