defmodule Fluid.Test.PpsUtils do
  # answers the question: `does the given list of pools form a pps?`
  def forms_pps?(list_of_pools, pps) do
    list_of_pools_id = list_of_pools |> Enum.map(& &1.id) |> Enum.sort()
    pps_pool_id = pps.pools |> Enum.map(& &1.id) |> Enum.sort()

    list_of_pools_id == pps_pool_id
  end

  @doc """
  the function is simplified version of

  ---

  case {forms_pps?([cp_1, fp_1], pps_1), forms_pps?([cp_1, fp_1], pps_2)} do
        {true, false} ->
          assert true

        {false, true} ->
          assert true

        incorrect ->
          IO.inspect(incorrect)
          assert false
      end

  """
  def forms_pps_either?(list_of_pools, list_of_pps) do
    for pps <- list_of_pps, reduce: [] do
      acc ->
        [forms_pps?(list_of_pools, pps) | acc]
    end
    # the list_of_pools must form a part of ONE AND ONLY ONE pps
    # if this is not the case, then pps are having overlap and the calculation of pps is wrong.
    |> then(&(Enum.count(&1, fn x -> x == true end) == 1))
  end
end
