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
    {:cont, changeset}
    |> ensure_source_dest_types(source, dest)
    |> src_dest_from_different_wh(source, dest)
    |> src_dest_type_validations(source, dest)
    |> unwrap()
  end

  def ensure_source_dest_types({:cont, cs}, source, dest) do
    case {source, dest} do
      {%Tank{capacity_type: :capped}, %Pool{capacity_type: pool_capacity}}
      when pool_capacity in [:fixed, :capped] ->
        # if tank or pool are not uncapped, halt the pipeline and let it pass.
        # todo find out why?
        {:cont, cs}

      # {:halt, cs}

      {%Pool{capacity_type: pool_capacity}, %Tank{capacity_type: :capped}}
      when pool_capacity in [:fixed, :capped] ->
        # if tank or pool are not uncapped, halt the pipeline and let it pass.
        {:halt, cs}

      _ ->
        {:cont, cs}
    end
  end

  defp src_dest_from_different_wh({:cont, changeset}, source, dest) do
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

      {:halt, changeset}
    else
      {:cont, changeset}
    end
  end

  defp src_dest_from_different_wh({:halt, changeset}, _source, _dest), do: {:halt, changeset}

  defp src_dest_type_validations({:cont, changeset}, source, dest) do
    case {source, dest} do
      # Every UCT is linked either to one or more SUCTs and/or to one or more UCPs
      # todo : ensure that both tank and pool are from different warehouses

      {%Tank{capacity_type: :uncapped, location_type: :in_wh}, %Pool{capacity_type: :uncapped, location_type: :in_wh}} ->
        cs =
          changeset
          |> Ash.Changeset.change_attribute(:source, to_map(source))
          |> Ash.Changeset.change_attribute(:destination, to_map(dest))

        {:cont, cs}

      {%Tank{capacity_type: :uncapped, location_type: :in_wh}, %Tank{capacity_type: :uncapped, location_type: :standalone}} ->
        cs =
          changeset
          |> Ash.Changeset.change_attribute(:source, source)
          |> Ash.Changeset.change_attribute(:destination, dest)

        {:cont, cs}

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

        {:halt, cs}
    end
  end

  defp src_dest_type_validations({:halt, changeset}, _source, _dest) do
    {:halt, changeset}
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
