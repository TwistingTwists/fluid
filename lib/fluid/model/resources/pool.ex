defmodule Fluid.Model.Pool do
  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJason.Extension]

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string, allow_nil?: true
    attribute :tag_id, :uuid, allow_nil?: true

    attribute :capacity_type, Fluid.PoolTypes do
      description("fixed, uncapped, or capped pools can exist")
    end

    attribute :location_type, Fluid.TankLocationTypes do
      description("Whether it is standalone or in warehouse")
    end

    attribute :volume, :integer do
      default 0
      description "the volume of water `currently` in that pool."
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    # toask cannot belong to both at the same time?
    belongs_to(:warehouse, Fluid.Model.Warehouse)
    # toask can belong_to world directly - iff pool is standalone?
    belongs_to(:world, Fluid.Model.World)
  end

  actions do
    defaults([:update])

    read :read_all do
      primary? true
    end

    read :read_by_id do
      get_by [:id]
    end

    create :create do
      change load([:world, :warehouse])
    end

    update :update_volume do
      accept [:volume]
      change load([:warehouse])
    end

    # create :create_with_world do
    #   argument :world, World, allow_nil?: true
    #   change load([:world, :warehouse])

    #   change manage_relationship(:world, type: :append_and_remove)
    # end

    # create :create_with_warehouse do
    #   argument :warehouse, Warehouse, allow_nil?: true
    #   change load([:world, :warehouse])

    #   change manage_relationship(:warehouse, type: :append_and_remove)
    # end
  end

  code_interface do
    define_for(Fluid.Model.Api)

    define(:create)
    define :update_volume
    # define :create_with_world, args: [:world]
    # define :create_with_warehouse, args: [:warehouse]

    define(:read_all)
    define(:read_by_id, args: [:id])

    define(:update)
  end

  postgres do
    table("pools")
    repo(Fluid.Repo)
  end

  jason do
    merge(%{module: "#{__MODULE__}"})
  end
end
