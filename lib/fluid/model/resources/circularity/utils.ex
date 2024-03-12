defmodule Fluid.Model.Circularity.Utils do
  alias Fluid.Model

  @doc """
  Given a warehouse, in a world, calculate all the connections 
  todo ensure the world id matches when you read all tags.

  all_tags: represents all the tags in the world (where warehouse exists)
    > all_tags is passed explicitly because of recursive nature of euler_algorithm which uses this
    > Since euler algorithm requires to delete the tags / connections from feeder nodes.
  """
  def calculate_outbound_connections(%Model.Warehouse{} = wh, all_tags \\ nil) do
    all_tags =
      if all_tags do
        all_tags
      else
        Model.Tag.read_all!()
      end

    tank_ids = Enum.map(wh.tanks, & &1.id)
    pool_ids = Enum.map(wh.pools, & &1.id)
    tank_or_pool_ids = tank_ids ++ pool_ids

    Enum.reduce(all_tags, [], fn tag, acc ->
      if tag.source["id"] in tank_or_pool_ids do
        [tag | acc]
      else
        acc
      end
    end)
  end

  @doc """
  todo ensure the world id matches when you read all tags
  """
  def calculate_inbound_connections(%Model.Warehouse{} = wh, all_tags \\ nil) do
    all_tags =
      if all_tags do
        all_tags
      else
        Model.Tag.read_all!()
      end

    tank_ids = Enum.map(wh.tanks, & &1.id)
    pool_ids = Enum.map(wh.pools, & &1.id)
    tank_or_pool_ids = tank_ids ++ pool_ids

    Enum.reduce(all_tags, [], fn tag, acc ->
      if tag.destination["id"] in tank_or_pool_ids do
        [tag | acc]
      else
        acc
      end
    end)
  end

  def preserve_original_connection_list(%{all: all, determinate: determinate, indeterminate: indeterminate}) do
    updated_determinate =
      for {wh_id, circularity} <- determinate, into: %{} do
        wh = Model.Warehouse.read_by_id!(wh_id)
        inbound_connections = calculate_inbound_connections(wh)
        outbound_connections = calculate_outbound_connections(wh)
        {wh_id, Map.merge(circularity, %{inbound_connections: inbound_connections, outbound_connections: outbound_connections})}
      end

    updated_indeterminate =
      for {wh_id, circularity} <- indeterminate, into: %{} do
        wh = Model.Warehouse.read_by_id!(wh_id)
        inbound_connections = calculate_inbound_connections(wh)
        outbound_connections = calculate_outbound_connections(wh)
        {wh_id, Map.merge(circularity, %{inbound_connections: inbound_connections, outbound_connections: outbound_connections})}
      end

    %{all: all, determinate: updated_determinate, indeterminate: updated_indeterminate}
  end

  @doc """
  Visual Easy representation of tag for debugging
  """
  def tag_to_repr(%{source: %{"warehouse_id" => in_id}, destination: %{"warehouse_id" => out_id}} = _tag) do
    """
    #{Model.Warehouse.read_by_id!(in_id).name} => #{Model.Warehouse.read_by_id!(out_id).name}
    """
  end
end
