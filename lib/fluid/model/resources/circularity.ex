defmodule Fluid.Model.Circularity do
  @moduledoc """
  Only related to wh details for circularity
  """
  use Ash.Resource
  # , data_layer: :embedded

  # import Fluid.Model.Circularity.Utils
  alias Fluid.Model
  alias Fluid.Model.Tag

  attributes do
    uuid_primary_key(:id)
    attribute(:wh_id, :string)
    attribute(:name, :string)
    # warehouse
    attribute(:wh, :map)
    attribute(:inbound_connections, {:array, :struct}, constraints: [items: [instance_of: Fluid.Model.Tag]])
    attribute(:outbound_connections, {:array, :struct}, constraints: [items: [instance_of: Fluid.Model.Tag]])

    attribute(:is_feeder_node, :boolean, default: nil)
    attribute(:is_unconnected_node, :boolean, default: nil)
    # representing as ascii value for easier code.
    # "0" is 48 and so on
    # "A" is 65 and so on
    attribute(:determinate_classes, {:array, :integer}, default: [])
    attribute(:indeterminate_classes, {:array, :integer}, default: [])
  end

  actions do
    defaults([:create])
  end

  code_interface do
    define_for(Fluid.Model.Api)

    define(:create)
  end

  # NORMAL MODULE
  # --------------------

  def calculate_feeder_and_unconnected_nodes(%{all: list_of_warehouses}) do
    # base case starts with all tags / connections
    all_tags = Tag.read_all!()

    # we start with every warehouse being indeterminate. And keep deleting determinate from that list
    args = %{all: list_of_warehouses, indeterminate: list_of_warehouses, determinate: %{}}

    do_calculate_feeder_and_unconnected_nodes(args, all_tags)
  end

  defp do_calculate_feeder_and_unconnected_nodes(
         %{all: total_wh, indeterminate: list_of_warehouses, determinate: determinate_wh_map},
         all_tags
       ) do
    {new_wh_acc, tag_acc} =
      for wh <- list_of_warehouses, reduce: {%{}, all_tags} do
        {wh_acc, tag_acc} ->
          inbound_connections = Model.Circularity.Utils.calculate_inbound_connections(wh, all_tags)
          outbound_connections = Model.Circularity.Utils.calculate_outbound_connections(wh, all_tags)

          is_feeder_node = Model.Circularity.Utils.is_feeder_node(inbound_connections, outbound_connections)
          is_unconnected_node = Model.Circularity.Utils.is_unconnected_node(inbound_connections, outbound_connections)

          new_wh_acc =
            Map.put(
              wh_acc,
              wh.id,
              Model.Circularity.create!(%{
                is_feeder_node: is_feeder_node,
                is_unconnected_node: is_unconnected_node,
                outbound_connections: outbound_connections,
                inbound_connections: inbound_connections,
                wh_id: wh.id,
                name: wh.name,
                wh: wh
              })
            )

          {new_wh_acc, tag_acc}
      end

    {%{all: total_wh, indeterminate: new_wh_acc, determinate: determinate_wh_map}, tag_acc}
  end

  # If there are no edges left + if there are some warehouses in indeterminate list => all must be unconnected
  # :up: is not being used directly in the algorithm. But it is implied.
  def run_euler_algorithm({%{all: total_wh, indeterminate: list_of_warehouses_map, determinate: determinate_wh_map}, tags_list}) do
    {after_wh_list, after_tags} =
      for {wh_id, wh_map} <- list_of_warehouses_map, reduce: {list_of_warehouses_map, tags_list} do
        {wh_acc, tags_acc} ->
          update_wh_map(wh_map, {wh_acc, tags_acc}, wh_id)
      end

    # if wh_id is in indeterminate_circularity list => reject it from determinate_wh_map
    updated_determinate_wh_map = update_determinate_map(list_of_warehouses_map, after_wh_list)
    determinate_wh_map = Map.merge(determinate_wh_map, updated_determinate_wh_map)

    # if no nodes were deleted => do not run_euler_algorithm() further
    if map_size(after_wh_list) < map_size(list_of_warehouses_map) do
      indeterminate_wh_list = transform_to_wh_from_wh_map(after_wh_list)

      warehouse_current_status = %{
        all: total_wh,
        indeterminate: indeterminate_wh_list,
        determinate: determinate_wh_map
      }

      do_calculate_feeder_and_unconnected_nodes(warehouse_current_status, after_tags)
      |> run_euler_algorithm()
    else
      %{all: total_wh, indeterminate: after_wh_list, determinate: determinate_wh_map}
    end
  end

  @doc """
  There are 3 cases to update the circularity.

  1. for a feeder node => delete the outbound connections + delete the feeder node
  2. for an unconnected node => delete the unconnected node
  3. for any other node => don't change anything
  """
  def update_wh_map(
        %{
          is_feeder_node: true,
          is_unconnected_node: false,
          outbound_connections: outbound_connections
        } = _wh_map,
        {wh_acc, tags_acc},
        wh_id
      ) do
    # remove all the outbound connections from the warehouse (node)
    outbound_connections_ids = Enum.map(outbound_connections, & &1.id)

    left_tags =
      Enum.reject(tags_acc, fn tag ->
        tag.id in outbound_connections_ids
      end)

    # delete the feeder nodes
    {Map.delete(wh_acc, wh_id), left_tags}
  end

  def update_wh_map(
        %{
          is_feeder_node: false,
          is_unconnected_node: true,
          inbound_connections: _inbound_connections,
          outbound_connections: _outbound_connections
        } = _wh_map,
        {wh_acc, tags_acc},
        wh_id
      ) do
    {Map.delete(wh_acc, wh_id), tags_acc}
  end

  def update_wh_map(
        %{is_feeder_node: false, is_unconnected_node: false} = _wh_map,
        {wh_acc, tags_acc},
        _wh_id
      ) do
    {wh_acc, tags_acc}
  end

  defp update_determinate_map(list_of_warehouses_map, after_wh_list) do
    Enum.reject(list_of_warehouses_map, fn {wh_id, _wh_map} ->
      if after_wh_list[wh_id] do
        true
      end
    end)
    |> Enum.into(%{})
  end

  defp transform_to_wh_from_wh_map(after_wh_list) do
    Enum.map(after_wh_list, fn {_wh_id, %{wh: wh}} -> wh end)
  end
end
