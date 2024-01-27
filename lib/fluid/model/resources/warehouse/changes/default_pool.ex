defmodule Fluid.Model.Warehouse.Changes.AddDefaultPool do
  use Ash.Resource.Change
  alias Fluid.Model.Pool

  def change(changeset, _opts, _context) do
    # todo improve - create a suct only if the world doesn't have one.
    {:ok, pool} =
      Pool.create(%{location_type: :in_wh})

    Ash.Changeset.set_argument(changeset, :pools, [pool])
  end
end
