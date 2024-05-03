defmodule Fluid.Model.PPS do
  @moduledoc """
  PPS (collection of pools) in a world
  """
  use Ash.Resource
  # data_layer: :embedded

  alias Fluid.Model

  @pps_types Fluid.Model.PPS.PPSTypes

  attributes do
    uuid_primary_key(:id)

    attribute(:type, @pps_types,
      description:
        "PPS is invalid if it has mix of indeterminate and determinate warehouses. which is indicated by type: :det_indet_both"
    )

    attribute(:pools, {:array, :struct},
      constraints: [
        items: [instance_of: Model.Pool]
      ],
      description: """
      These pools form a part of PPS calculated on basis of:
      ```
      A given PPS exists when
      (a) a CT tags more than one pool and
      (b) at least one of those tagged pools is tagged by at least one more CT
      ```
      The type of pps - is given by `:type`
      """
    )

    # todo [refactor]: make it a calculation based on `pool.warehouse_id`
    # attribute(:related_wh, {:array, :struct},
    #   constraints: [
    #     items: [instance_of: Model.Warehouse]
    #     # items: [instance_of: Model.Circularity]
    #   ],
    #   description: """
    #   depending on #{@pps_types} - list of warehouses

    #   :excess_circularity - warehouses which must be a mix of determinate and indeterminate warehouses
    #   :det_pps_only - warehouses which must be  determinate warehouses
    #   :indet_pps_only - warehouses which must be  indeterminate warehouses

    #   """
    # )
  end

  calculations do
    calculate(:related_wh, {:array, :struct}, {WhCalculations, field: :pools},
      constraints: [items: [instance_of: Model.Warehouse]],
      description: """
      depending on #{@pps_types} - list of warehouses

      :excess_circularity - warehouses which must be a mix of determinate and indeterminate warehouses
      :det_pps_only - warehouses which must be  determinate warehouses
      :indet_pps_only - warehouses which must be  indeterminate warehouses

      """
    )
  end

  actions do
    defaults([:read, :update])

    create :create do
      change(load([:related_wh]))
    end
  end

  code_interface do
    define_for(Fluid.Model.Api)

    define(:create)
  end
end

defmodule WhCalculations do
  @moduledoc """
  Calculates warehouse for given list of pools
  """
  use Ash.Calculation
  alias Fluid.Model

  @doc """
  Given a list of pps, return a list of the associated warehouses for each pps.

  The associated warehouses are stored as a value under key `opts[:field]` in PPS struct.
  """
  @impl Ash.Calculation
  def calculate(pps_list, opts, _resolution) do
    fields = List.wrap(opts[:field])
    # This way only one db query is made to get all warehouses without preloading tanks / pools etc
    all_wh_hashmap =
      Model.Warehouse.read_all_bare!()
      |> Map.new(fn %{id: wh_id} = wh -> {wh_id, wh} end)

    {:ok,
     Enum.map(pps_list, fn pps ->
       pps
       |> Kernel.get_in(Enum.map(fields, &Access.key/1))
       |> get_related_warehouses(all_wh_hashmap)
     end)}
  end

  @doc """
  all_wh_hashmap : in this hashmap, key is warehouse_id and value is %Warehouse{}

  Given a list of pools, and the all_wh_hashmap, associate the pool with warehouse.
  """
  def get_related_warehouses(pools, all_wh_hashmap) do
    Enum.map(pools, fn %{warehouse_id: wh_id} ->
      Map.get(all_wh_hashmap, wh_id, nil)
    end)
    |> Enum.uniq()
  end
end
