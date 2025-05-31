defmodule SpecForgeWebWeb.Api.StatusController do
  use SpecForgeWebWeb, :controller
  
  action_fallback SpecForgeWebWeb.Api.FallbackController

  @doc """
  GET /api/status/:job_id
  Returns the status of a job.
  """
  def show(conn, %{"id" => job_id}) do
    case lookup_job(job_id) do
      {:ok, job_info} ->
        json(conn, format_job_status(job_id, job_info))
      
      {:error, :not_found} ->
        {:error, :not_found, "Job not found"}
    end
  end

  defp lookup_job(job_id) do
    case :ets.lookup(:specforge_jobs, job_id) do
      [{^job_id, job_info}] -> {:ok, job_info}
      [] -> {:error, :not_found}
    end
  end

  defp format_job_status(job_id, job_info) do
    base = %{
      job_id: job_id,
      type: job_info[:type],
      status: job_info[:status],
      started_at: job_info[:started_at]
    }
    
    case job_info[:status] do
      :processing ->
        base
      
      :completed ->
        base
        |> Map.put(:completed_at, job_info[:completed_at])
        |> Map.put(:result, job_info[:result])
      
      :failed ->
        base
        |> Map.put(:completed_at, job_info[:completed_at])
        |> Map.put(:error, job_info[:error])
    end
  end
end