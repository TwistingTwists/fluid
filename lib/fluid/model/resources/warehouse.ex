defmodule Fluid.Model.Warehouse do
  # alias Fluid.Model.Pool
  alias __MODULE__

  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    uuid_primary_key(:id)

    attribute(:name, :string, allow_nil?: false)

    # attribute :name, :string, allow_nil?: false
    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  relationships do
    belongs_to(:world, Fluid.Model.World)
    has_many(:tanks, Fluid.Model.Tank)
    has_many(:pools, Fluid.Model.Pool)
  end

  calculations do
    calculate(:count_uncapped_tank, :integer, {Warehouse.Calculations.UCT, field: :tanks})
    calculate(:count_pool, :integer, {Warehouse.Calculations.Pool, field: :pools})
    # actual structs with data

    calculate(:capped_pools, {:array, :struct}, {Warehouse.Calculations.PoolorTankType, field: :pools, type: :capped},
      constraints: [items: [instance_of: Fluid.Model.Pool]]
    )

    calculate(:fixed_pools, {:array, :struct}, {Warehouse.Calculations.PoolorTankType, field: :pools, type: :fixed},
      constraints: [items: [instance_of: Fluid.Model.Pool]]
    )

    calculate(:capped_tanks, {:array, :struct}, {Warehouse.Calculations.PoolorTankType, field: :tanks, type: :capped},
      constraints: [items: [instance_of: Fluid.Model.Tank]]
    )

    calculate(:fixed_tanks, {:array, :struct}, {Warehouse.Calculations.PoolorTankType, field: :tanks, type: :fixed},
      constraints: [items: [instance_of: Fluid.Model.Tank]]
    )
  end

  aggregates do
    count :count_ucp_cp, :pools do
      filter(expr(capacity_type in [:uncapped, :capped]))
    end
  end

  @load_fields [
    :tanks,
    :pools,
    :world,
    :count_uncapped_tank,
    :count_pool,
    :count_ucp_cp,
    :fixed_tanks,
    :fixed_pools,
    :capped_pools,
    :capped_tanks
  ]

  actions do
    defaults([:update])

    read :read_all do
      primary?(true)
      prepare(build(load: @load_fields))
    end

    read(:read_all_bare)

    read :read_by_id do
      prepare(build(load: @load_fields))
      get_by([:id])
    end

    create :create do
      primary?(true)

      argument(:tanks, {:array, Fluid.Model.Tank}, allow_nil?: true)
      argument(:pools, {:array, Fluid.Model.Pool}, allow_nil?: true)

      change(load(@load_fields))

      change({Fluid.Model.Warehouse.Changes.AddDefaultUCT, arg: :tanks, rel: :tanks})
      # change Fluid.Model.Warehouse.Changes.AddDefaultPool

      change(manage_relationship(:tanks, type: :append_and_remove))
      change(manage_relationship(:pools, type: :append_and_remove))
    end

    update :add_tank do
      argument(:tank, Fluid.Model.Tank, allow_nil?: false)

      change(load(@load_fields))

      # change {Fluid.Model.Changes.AddArgToRelationship, arg: :tank, rel: :tanks}
      change({Fluid.Model.Warehouse.Changes.AddDefaultUCT, arg: :tank, rel: :tanks})
      change(manage_relationship(:tank, :tanks, type: :append))
    end

    update :add_pool do
      argument(:pool, Fluid.Model.Pool, allow_nil?: false)

      change(load(@load_fields))

      change({Fluid.Model.Changes.AddArgToRelationship, arg: :pool, rel: :pools})
      # change {Fluid.Model.Warehouse.Changes.AddDefaultUCT, arg: :tank, rel: :tanks}

      change(manage_relationship(:pool, :pools, type: :append))
    end
  end

  changes do
    change(
      fn changeset, opts ->
        Ash.Changeset.after_transaction(
          changeset,
          fn
            changeset, {:ok, warehouse} ->
              # Logger.debug(warehouse)
              # Logger.debug("warehouse in after_transaction")

              if is_integer(warehouse.count_pool) and warehouse.count_pool < 1 do
                Logger.error("Pool Count should be greater than one.")

                # Ash.Changeset.add_errors(changeset, :pools , "Pool Count should be greater than one.")
                {:error, changeset}
              else
                Logger.debug("warehouse in after_transaction: ok warehouse")

                {:ok, warehouse}
              end

            changeset, error ->
              Logger.debug("warehouse in after_transaction error : #{inspect(error)}")

              {:error, error}
          end
        )
      end,
      on: [:create]
    )
  end

  code_interface do
    define_for(Fluid.Model.Api)

    # define :create, args: [:tanks, :pools]
    define(:create)

    define(:read_all)
    define(:read_all_bare)
    define(:read_by_id, args: [:id])

    define(:update)

    define(:add_tank, args: [:tank])
    define(:add_pool, args: [:pool])
  end

  postgres do
    table("warehouses")
    repo(Fluid.Repo)
  end
end
