defmodule Fluid.Test.Factory do
  alias Fluid.Model.Tank
  alias Fluid.Model.Pool

  def tank_params() do
    [
      %{
        location_type: :in_wh,
        capacity_type: :uncapped
      },
      %{
        location_type: :in_wh,
        capacity_type: :capped
      },
      %{
        location_type: :standalone,
        capacity_type: :uncapped
      }
    ]
  end

  def pool_params() do
    [
      %{
        location_type: :in_wh,
        capacity_type: :uncapped
      },
      %{
        location_type: :in_wh,
        capacity_type: :capped
      },
      %{
        location_type: :in_wh,
        capacity_type: :fixed
      },
      %{
        location_type: :standalone,
        capacity_type: :uncapped
      }
    ]
  end

  def tanks() do
    tank_params()
    |> Enum.map(fn tank_params ->
      {:ok, tank} =
        Tank.create(tank_params)

      tank
    end)
    # additionally sort tanks by id to ease out asssertion
    |> Enum.sort_by(& &1.id, :asc)
  end

  def pools() do
    pool_params()
    |> Enum.map(fn pool_params ->
      {:ok, pool} = Pool.create(pool_params)
      pool
    end)
    # additionally sort tanks by id to ease out asssertion
    |> Enum.sort_by(& &1.id, :asc)
  end
end
