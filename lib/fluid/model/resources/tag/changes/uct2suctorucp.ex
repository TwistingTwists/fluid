defmodule Fluid.Model.Warehouse.Changes.UCT2SUCTorUCP do
  use Ash.Resource.Change

  # alias Fluid.Model.World
  # alias Fluid.Model.Warehouse
  alias Fluid.Model.Pool
  alias Fluid.Model.Tank
  require Logger

  def change(changeset, _opts, _context) do
    source = Ash.Changeset.get_argument(changeset, :source)
    dest = Ash.Changeset.get_argument(changeset, :destination)

    case {source, dest} do
      # Every UCT is linked either to one or more SUCTs and/or to one or more UCPs
      # todo : ensure that both tank and pool are from different warehouses

      {%Tank{capacity_type: :uncapped, location_type: :in_wh}, %Pool{capacity_type: :uncapped, location_type: :in_wh}} ->
        changeset
        |> Ash.Changeset.change_attribute(:source, to_map(source))
        |> Ash.Changeset.change_attribute(:destination, to_map(dest))

      {%Tank{capacity_type: :uncapped, location_type: :in_wh},
       %Tank{capacity_type: :uncapped, location_type: :standalone}} ->
        changeset
        |> Ash.Changeset.change_attribute(:source, source)
        |> Ash.Changeset.change_attribute(:destination, dest)

      {source, dest} ->
        Logger.error("source: #{source.capacity_type} / #{source.location_type}")
        Logger.error("dest: #{dest.capacity_type} / #{dest.location_type}")

        Ash.Changeset.add_error(
          changeset,
          field: :source,
          message: """
          Every UCT is linked either to one or more SUCTs and/or to one or more.
          Given source: #{inspect(source)}
          Given dest: #{inspect(dest)}
          """
        )
    end
  end

  defp to_map(%s{} = struct_tank_pool) do
    map_args =
      Map.take(struct_tank_pool, [
        :id,
        :capacity_type,
        :location_type,
        :tag_id,
        :regularity_type,
        :warehouse_id
      ])

    Map.merge(map_args, %{entity_type: "#{s}"})
  end
end
