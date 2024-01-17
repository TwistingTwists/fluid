defmodule Fluid.Model.World do
  @moduledoc """
  World has a unique name.
  World has a SUCT.
  """

  # checklist
  # preload all calculations in read / create actions

  alias __MODULE__
  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  attributes do
    # uuid ensures uniqueness of world
    uuid_primary_key :id

    # ensure unique via a unique db constraint
    attribute :name, :string, allow_nil?: false

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :warehouses, Fluid.Model.Warehouse
    # todo validate that the tanks are only of type SUCT
    has_many :tanks, Fluid.Model.Tank
    # todo validate pools types if any
    has_many :pools, Fluid.Model.Pool
  end

  calculations do
    calculate :count_standalone_uncapped_tank, :integer, {World.Calculations.SUCT, field: :tanks}
  end

  actions do
    defaults [:update]

    read :read_all do
      prepare build(load: [:count_standalone_uncapped_tank])
      primary? true
    end

    read :read_by_id do
      prepare build(load: [:count_standalone_uncapped_tank])
      get_by [:id]
    end

    create :create do
      # change Fluid.Model.World.Changes.AddDefaultSUCT
      change load([:tanks, :pools, :warehouses, :count_standalone_uncapped_tank])
    end
  end

  code_interface do
    define_for Fluid.Model.Api

    define :create

    define :read_all
    define :read_by_id, args: [:id]

    define :update
  end

  postgres do
    table "worlds"
    repo Fluid.Repo
  end
end
