defmodule Fluid.Model.Warehouse.Changes.OnlyOneUCT do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
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
  end
end
