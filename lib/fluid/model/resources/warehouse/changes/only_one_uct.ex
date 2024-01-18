defmodule Fluid.Model.Warehouse.Changes.OnlyOneUCT do
  use Ash.Resource.Change
  alias Fluid.Model.Tank

  def change(changeset, _opts, _context) do
    changeset.data.count_uncapped_tank |> IO.inspect(label: " changeset.data.count_uncapped_tank")

    cond do
      changeset.data.count_uncapped_tank == 0 ->
        changeset

      changeset.data.count_uncapped_tank >= 1 ->
        Ash.Changeset.add_error(
          changeset,
          field: :tanks,
          message: "Warehouse always has ONLY one UCT. You cannot add more.",
          value: changeset.data.count_uncapped_tank
        )
    end

    # end
    |> IO.inspect(label: "Edited - changeset for warehouse \n")

    # Ash.Changeset.set_argument(changeset, :tanks, [tank])
    # |> IO.inspect(label: "NEW changeset for warehouse")

    # preload all tanks. Check if there is ONLY one uncapped tank.
    # Fluid.Model.Api.load(changeset.data)
  end
end
