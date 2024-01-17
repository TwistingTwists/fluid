defmodule Fluid.Model.World.Changes.AddDefaultSUCT do
  use Ash.Resource.Change
  alias Fluid.Model.Tank

  def change(changeset, _opts, _context) do
    {:ok, tank} =
      Tank.create(%{
        location_type: :standalone,
        capacity_type: :uncapped
      })

    Ash.Changeset.set_argument(changeset, :tanks, tank)
    |> IO.inspect(label: "Tanks please ")
  end
end
