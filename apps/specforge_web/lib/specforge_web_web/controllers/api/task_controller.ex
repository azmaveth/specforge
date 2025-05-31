defmodule SpecForgeWebWeb.Api.TaskController do
  use SpecForgeWebWeb, :controller
  
  alias SpecforgeCore.Impl.TaskPlannerImpl
  
  action_fallback SpecForgeWebWeb.Api.FallbackController

  @doc """
  POST /api/task
  Analyzes a task and returns an actionable plan.
  """
  def create(conn, params) do
    with {:ok, task_description} <- validate_task_params(params),
         {:ok, job_id} <- start_async_task(task_description, params) do
      conn
      |> put_status(:accepted)
      |> json(%{
        job_id: job_id,
        status: "processing",
        message: "Task analysis started"
      })
    end
  end

  defp validate_task_params(%{"task" => task}) when is_binary(task) do
    {:ok, task}
  end
  defp validate_task_params(_), do: {:error, :bad_request, "Missing or invalid 'task' parameter"}

  defp start_async_task(task_description, params) do
    # In a real implementation, this would use Task.Supervisor
    # For now, return a mock job ID
    job_id = generate_job_id()
    
    # Store job metadata in ETS or similar
    :ets.insert(:specforge_jobs, {job_id, %{
      type: :task,
      status: :processing,
      params: params,
      started_at: DateTime.utc_now()
    }})
    
    # Start async processing
    Task.start(fn ->
      process_task(job_id, task_description, params)
    end)
    
    {:ok, job_id}
  end

  defp process_task(job_id, task_description, params) do
    # Convert web params to core options
    options = build_options(params)
    
    result = case TaskPlannerImpl.analyze_task(task_description, options) do
      {:ok, plan} -> 
        %{status: :completed, result: plan}
      {:error, reason} -> 
        %{status: :failed, error: inspect(reason)}
    end
    
    # Update job status
    :ets.update_element(:specforge_jobs, job_id, {2, Map.merge(result, %{
      completed_at: DateTime.utc_now()
    })})
  end

  defp build_options(params) do
    %{}
    |> maybe_add_option(:model, params["model"])
    |> maybe_add_option(:search, params["search"])
    |> maybe_add_option(:template, params["template"])
    |> maybe_add_option(:validate, params["validate"] != false)
  end

  defp maybe_add_option(opts, _key, nil), do: opts
  defp maybe_add_option(opts, key, value), do: Map.put(opts, key, value)

  defp generate_job_id do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
end