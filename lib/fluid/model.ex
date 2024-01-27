defmodule Fluid.Model do
  @moduledoc """
  Context layer for operating on models
  * World, Warehouse, Tank, Tag
  """
  alias Fluid.Model.Warehouse
  # alias Fluid.Model.Pool
  # alias Fluid.Model.Tank
  # alias Fluid.Model.Tag

  def create_world(params, opts \\ []) do
    # it is important to convert `params` to map and `opts` to be a keyword list
    # https://hexdocs.pm/ash/code-interface.html#using-the-code-interface
    params = Map.new(params)

    Fluid.Model.World
    |> Ash.Changeset.for_create(:create, params, opts)
    |> Fluid.Model.Api.create()
  end

  def create_warehouse(params, opts \\ []) do
    params = Map.new(params)

    Warehouse
    |> Ash.Changeset.for_create(:create, params, opts)
    |> Fluid.Model.Api.create()
  end

  # add_tank
  # add_pool
  # connect(capped_tank_wh1, capped_pool_wh2)
  # >> Run just the last test
  #

  # def create_tank_standalone(%Fluid.Model.World{} = world, params, opts \\ []) do
  #   params =
  #     params
  #     |> Map.new()
  #     |> dbg()
  #     # |> Map.merge(%{
  #     #   location_type: :standalone,
  #     #   capacity_type: :uncapped
  #     # })
  #     |> Map.merge(%{world: world})

  #   World
  #   |> Ash.Changeset.for_create(:create_tank, params, opts)
  #   |> Fluid.Model.Api.create()
  # end

  # def create_tank_in_warehouse(%Warehouse{} = warehouse, params, opts \\ []) do
  #   params =
  #     params
  #     |> Map.new()
  #     |> Map.merge(%{
  #       location_type: :in_wh
  #       # make no assumption about :capacity_type of tank
  #     })

  #   Warehouse
  #   |> Ash.Changeset.for_create(:udpate_with_tank, warehouse, params, opts)
  #   |> Fluid.Model.Api.create()
  # end

  # def create_pool_in_warehouse(%Warehouse{} = warehouse, params, opts \\ []) do
  #   params =
  #     params
  #     |> Map.new()
  #     |> Map.merge(%{
  #       location_type: :in_wh
  #       # make no assumption about :capacity_type of pool
  #     })

  #   Warehouse
  #   |> Ash.Changeset.for_create(:create_pool, warehouse, params, opts)
  #   |> Fluid.Model.Api.create()
  # end

  # def add_tanks_to_warehouse(%Warehouse{} = warehouse, %Tank{} = tank) do
  #   add_tanks_to_warehouse(warehouse, [tank])
  # end

  # def add_tanks_to_warehouse(warehouse, tanks) do
  #   Enum.reduce_while(tanks, nil, fn
  #     tank, _acc ->
  #       case Warehouse.add_tank(warehouse, tank) do
  #         {:ok, updated_warehouse} ->
  #           {:cont, {:ok, updated_warehouse}}

  #         {:error, error} ->
  #           {:halt, {:error, error}}
  #       end
  #   end)
  # end
end
