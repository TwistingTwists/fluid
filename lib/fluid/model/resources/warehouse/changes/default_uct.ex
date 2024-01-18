defmodule Fluid.Model.Warehouse.Changes.AddDefaultUCT do
  use Ash.Resource.Change
  alias Fluid.Model.Tank

  def change(changeset, _opts, _context) do
    # todo improve - create a suct only if the world doesn't have one.
    {:ok, tank} =
      Tank.create(%{
        location_type: :in_wh,
        capacity_type: :capped
      })

    Ash.Changeset.set_argument(changeset, :tanks, [tank])
  end
end
