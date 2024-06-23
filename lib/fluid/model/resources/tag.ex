defmodule Fluid.Model.Tag do
  @moduledoc """
  Represents a connection between
  * a pool and a tank
  * two tanks

  with constraints modelled as changesets
  """

  alias __MODULE__
  alias Fluid.Model

  require Logger

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  @load_fields [ :allocation]

  attributes do
    uuid_primary_key :id

    # https://github.com/rellen/ash/blob/37b0c4d9d0b3ee144c13293c73636c25cbf9be86/test/type/union_test.exs#L5
    attribute :source, :map, allow_nil?: false
    attribute :destination, :map, allow_nil?: false

    attribute :user_defined_tag, :string,
      description:
        "Tag which contains Primary Tag Rank and Secondary Tag Rank in a tuple format. {:primary_tag_tank, :secondar_tag_rank}. User Input is taken and stored in database."

    create_timestamp :created_at
    update_timestamp :updated_at
  end

  calculations do
    calculate :tag, :struct, Tag.TagCalculation,
      constraints: [instance_of: Model.Tag.TagRank],
      description: """
      Tag which contains Primary Tag Rank and Secondary Tag Rank. For all practical use cases, this calculation is used.
      """
  end

  relationships do
    has_one :allocation, Model.Allocation
  end

  actions do
    defaults [:update]

    read :read_all do
      primary? true
      prepare build(load: @load_fields)

    end

    read :read_by_id do
      get_by [:id]
      prepare build(load: @load_fields)

    end

    create :create do
      primary? true
      # argument :source, Tank | Pool, allow_nil?: false
      argument :source, :map, allow_nil?: false
      argument :destination, :map, allow_nil?: false

      change Fluid.Model.Warehouse.Changes.UCT2SUCTorUCP
      change load(@load_fields)
    end

    create :create_reverse do
      # argument :source, Tank | Pool, allow_nil?: false
      # argument(:source, :map, allow_nil?: false)
      # argument(:destination, :map, allow_nil?: false)

      # change(Fluid.Model.Warehouse.Changes.UCT2SUCTorUCP)
      # change load([:world, :warehouse])
    end
  end

  code_interface do
    define_for Fluid.Model.Api

    define :create, args: [:source, :destination]
    define :create_reverse, args: [:source, :destination]

    define :read_all
    define :read_by_id, args: [:id]

    define :update
  end

  postgres do
    table "tags"
    repo Fluid.Repo
  end

  ########
  # utils
  ########

end
