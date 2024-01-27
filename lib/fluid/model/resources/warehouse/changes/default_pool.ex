defmodule Fluid.Model.Warehouse.Changes.AddDefaultPool do
  use Ash.Resource.Change
  alias Fluid.Model.Pool

  def change(changeset, _opts, _context) do
    # todo improve - create a suct only if the world doesn't have one.
    pool_args = Ash.Changeset.get_argument(changeset, :pools)

    process_pools(pool_args, changeset)
  end

  def process_pools(val, changeset) when val in [[], nil] do
    # create a default uct
    {:ok, pool} =
      Pool.create(%{
        location_type: :in_wh,
        capacity_type: :uncapped
      })

    Ash.Changeset.set_argument(changeset, :pools, [pool])
  end

  def process_pools(pool_args, changeset) when is_list(pool_args) do
    # given a set of pools, add them to warehouse

    if Enum.any?(pool_args, fn
         %Pool{location_type: location_type} = _pool when location_type != :in_wh -> true
         _ -> false
       end) do
      Ash.Changeset.add_error(changeset,
        field: :pools,
        message: """
        Expected: Warehouse cannot have a pool whose location_type is not `:in_wh`.
        Got: #{inspect(pool_args)}
        """
      )
    else
      changeset
    end
  end
end
