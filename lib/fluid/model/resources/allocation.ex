defmodule Fluid.Model.Allocation do
  @moduledoc """

  Allocation: The interim step of calculating the amount of water that is assigned from a pool to a
  CT but prior to distributing such water. Allocations may undergo adjustments (e.g.,
  proportional reduction) prior to distribution.

  """
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer

  alias Fluid.Model

  attributes do
    uuid_primary_key :id

    # attribute :from, {:array, :struct}, constraints: [items: [instance_of: Fluid.Model.Tag]]
    # attribute :to, :string
    attribute :volume, :string

    attribute :stage, :string,
      default: "",
      description: """
      Stage defines what stage of allocation that is done.

      1. allocations_module: allocation of water from pools of equal Pool Rank to tags of
      equal rank (be they Primary Tag Ranks or Secondary Tag Ranks)

      2. pool_1_1T_to_T1: pools of rank 1 with Tag 1T  => Within this set of 1T tags, first allocate water from pools of Pool Rank 1 to their
      corresponding CTs via any tags with Secondary Tag Rank T1
        - adjust as per residual capacity of tank
        - distribute

      3. pool_1_1T_to_T2, pool_1_1T_to_T3 and so on.

      further, algo asks to do this: pool_2_1T_to_T1 , pool_2_1T_to_T2, pool_2_1T_to_T3 and so on

      4. pool_1_2T_to_T1: pools of rank 1 with Tag 2T

      5. pool_1_2T_to_T2, pool_1_2T_to_T3

      further, algo asks to do this: pool_2_2T_to_T1 , pool_2_2T_to_T2, pool_2_2T_to_T3 and so on
      """
  end

  relationships do
    belongs_to :tag, Model.Tag
  end

  postgres do
    table "allocations"
    repo Fluid.Repo
  end
end
