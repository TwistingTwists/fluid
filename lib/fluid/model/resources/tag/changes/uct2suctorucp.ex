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

    # if this pipeline fails =>  add relevant error to changeset at failure step and doesn't operate further on changeset
    {:ok, changeset}
    |> src_dest_from_different_wh(source, dest)
    |> src_dest_type_validations(source, dest)
    |> unwrap()
  end

  def src_dest_from_different_wh({:ok, changeset}, source, dest) do
    if source.warehouse_id == dest.warehouse_id do
      changeset
      |> Ash.Changeset.add_error(
        changeset,
        field: :source,
        message: """
        Source and Destination must be in different warehouses.
        Got: source.warehouse_id = #{source.warehouse_id}
        Got: dest.warehouse_id = #{dest.warehouse_id}
        """
      )

      {:error, changeset}
    else
      {:ok, changeset}
    end
  end

  # def src_dest_from_different_wh({:error, changeset}, _source, _dest), do: {:error, changeset}

  def src_dest_type_validations({:ok, changeset}, source, dest) do
    case {source, dest} do
      # Every UCT is linked either to one or more SUCTs and/or to one or more UCPs
      # todo : ensure that both tank and pool are from different warehouses

      {%Tank{capacity_type: :uncapped, location_type: :in_wh}, %Pool{capacity_type: :uncapped, location_type: :in_wh}} ->
        cs =
          changeset
          |> Ash.Changeset.change_attribute(:source, to_map(source))
          |> Ash.Changeset.change_attribute(:destination, to_map(dest))

        {:ok, cs}

      {%Tank{capacity_type: :uncapped, location_type: :in_wh},
       %Tank{capacity_type: :uncapped, location_type: :standalone}} ->
        cs =
          changeset
          |> Ash.Changeset.change_attribute(:source, source)
          |> Ash.Changeset.change_attribute(:destination, dest)

        {:ok, cs}

      {source, dest} ->
        Logger.error("source: #{source.capacity_type} / #{source.location_type}")
        Logger.error("dest: #{dest.capacity_type} / #{dest.location_type}")

        cs =
          Ash.Changeset.add_error(
            changeset,
            field: :source,
            message: """
            Every UCT is linked either to one or more SUCTs and/or to one or more.
            Given source: #{inspect(source)}
            Given dest: #{inspect(dest)}
            """
          )

        {:error, cs}
    end
  end

  def src_dest_type_validations({:error, changeset}, _source, _dest) do
    {:error, changeset}
  end

  def unwrap({_, changeset}), do: changeset

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
