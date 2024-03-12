defmodule Fluid.Model.Circularity.Utils do
  alias Fluid.Model

  @doc """
  Given a warehouse, in a world, calculate all the connections 
  todo ensure the world id matches when you read all tags.

  all_tags: represents all the tags in the world (where warehouse exists)
    > all_tags is passed explicitly because of recursive nature of euler_algorithm which uses this
    > Since euler algorithm requires to delete the tags / connections from feeder nodes.
  """
  def calculate_outbound_connections(%Model.Warehouse{} = wh) do
    calculate_outbound_connections(wh, nil)
  end

  def calculate_outbound_connections(%Model.Warehouse{} = wh, nil = _all_tags) do
    do_calculate_outbound_connections(wh, Model.Tag.read_all!())
  end

  def calculate_outbound_connections(%Model.Warehouse{} = wh, all_tags) do
    do_calculate_outbound_connections(wh, all_tags)
  end

  defp do_calculate_outbound_connections(wh, all_tags) do
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
  def calculate_inbound_connections(%Model.Warehouse{} = wh) do
    calculate_inbound_connections(wh, nil)
  end

  def calculate_inbound_connections(%Model.Warehouse{} = wh, nil = _all_tags) do
    do_calculate_inbound_connections(%Model.Warehouse{} = wh, Model.Tag.read_all!())
  end

  def calculate_inbound_connections(%Model.Warehouse{} = wh, all_tags) do
    do_calculate_inbound_connections(%Model.Warehouse{} = wh, all_tags)
  end

  defp do_calculate_inbound_connections(%Model.Warehouse{} = wh, all_tags) do
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
  if inbound_connections == [] and length(outbound_connections) >= 1, do: true, else: false
  """
  def is_feeder_node([] = _inbound_connections, outbound_connections) do
    length(outbound_connections) >= 1
  end

  def is_feeder_node(_inbound_connections, _outbound_connections) do
    false
  end

  @doc """
  if inbound_connections == [] and outbound_connections == [], do: true, else: false
  """
  def is_unconnected_node([] = _inbound_connections, [] = _outbound_connections) do
    true
  end

  def is_unconnected_node(_inbound_connections, _outbound_connections) do
    false
  end

  @doc """
   Enum.all?(wh.pools, fn
                %{capacity_type: capacity} when capacity not in [:uncapped, :capped] -> true
                _ -> false
              end)
  """
  def is_class_0?(pools) do
    Enum.all?(pools, fn
      %{capacity_type: capacity} when capacity not in [:uncapped, :capped] -> true
      _ -> false
    end)
  end

  @doc """
   
  if is_class_0? do
    Map.put(wh_circularity, :determinate_classes, [?0] ++ wh_circularity.determinate_classes)
  else
    wh_circularity
  end

  """
  def update_determinate_class_for_wh_circularity(wh_circularity, class_to_insert, true = _is_class_0) do
    Map.put(wh_circularity, :determinate_classes, [class_to_insert] ++ wh_circularity.determinate_classes)
  end

  def update_determinate_class_for_wh_circularity(wh_circularity, _class_to_insert, false = _is_class_0) do
    wh_circularity
  end

  @doc """
  decides whether or not to further subclassify.

  If there are still warehouse circularity left to classify , go on.
  """
  def further_subclassify?(updated_rest_determinate_wh_map) do
    Enum.any?(updated_rest_determinate_wh_map, fn
      {_wh_id,
       %Model.Circularity{
         determinate_classes: []
       }} ->
        true

      _ ->
        false
    end)
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
