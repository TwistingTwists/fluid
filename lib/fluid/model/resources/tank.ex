defmodule Fluid.Model.Tank do
  @moduledoc """
  Some attributes like :applicable_capacity, :residual_capacity only make sense for capped tank.
  Maybe write a validation around it.
  """
  require Logger

  alias Fluid.Model

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJason.Extension]

  # alias Fluid.Model.World
  # alias Fluid.Model.Warehouse

  @load_fields [:residual_capacity, :world, :warehouse]

  attributes do
    uuid_primary_key :id

    attribute :name, :string, allow_nil?: true
    attribute :tag_id, :uuid, allow_nil?: true

    attribute :capacity_type, Fluid.TankCapacityTypes do
      description "uncapped, capped"
    end

    attribute :total_capacity, :integer do
      description "The capacity of a CT when it is empty."
    end

    attribute :volume, :integer do
      default 0
      description "the volume of water `currently` in that CT."
    end

    # attribute :residual_capacity, :integer do
    #   description "total_capacity - volume"
    # end

    attribute :applicable_capacity, :integer do
      description "The capacity of a CT that is used for allocation calculations. It can equal either the
      Residual Capacity of the CT or the Total Capacity of the CT. The default setting is for
      it to equal the Residual Capacity of the CT, but the user can change this setting for
      each CT as they wish."
    end

    attribute :regularity_type, Fluid.TankRegularityTypes do
      description "regular tanks are default"
      default :regular
    end

    attribute :location_type, Fluid.TankLocationTypes do
      description "Whether it is standalone or in warehouse"
    end

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  calculations do
    calculate :residual_capacity, :integer, expr(total_capacity - volume) do
      description "total_capacity - volume"
    end
  end

  relationships do
    # toask cannot belong to both at the same time?
    belongs_to :warehouse, Fluid.Model.Warehouse
    # toask can belong_to world directly - iff pool is standalone?
    belongs_to :world, Fluid.Model.World
    # belongs_to :tag, Fluid.Model.Tag
  end

  actions do
    defaults [:update]

    read :read_all do
      primary? true
    end

    read :read_by_id do
      get_by [:id]
      prepare build(load: @load_fields)
    end

    create :create do
      primary? true
      change load(@load_fields)
    end

    update :update_volume do
      accept [:volume]
      change load(@load_fields)
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
    define_for Fluid.Model.Api

    define :create
    # define :update_volume
    # define :create_with_world, args: [:world]
    # define :create_with_warehouse, args: [:warehouse]

    define :read_all
    define :read_by_id, args: [:id]

    define :update
  end

  postgres do
    table "tanks"
    repo Fluid.Repo
  end

  jason do
    merge(%{module: "#{__MODULE__}"})
  end

  ###########
  #  normal module with helper API functions
  ###########

  def is_capped?(%{capacity_type: capacity_type}), do: capacity_type == :capped
  def is_uncapped?(%{capacity_type: capacity_type}), do: capacity_type == :uncapped

  # def in_wh?(tank, %Model.Warehouse{id: warehouse_id}), do: in_wh?(tank, warehouse_id)
  # def in_wh?(tank, warehouse_id), do: tank.location_type == :in_wh && tank.warehouse_id == warehouse_id
end
