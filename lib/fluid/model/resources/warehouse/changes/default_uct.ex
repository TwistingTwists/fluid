defmodule Fluid.Model.Warehouse.Changes.AddDefaultUCT do
  use Ash.Resource.Change
  alias Fluid.Model.Tank

  require Logger

  @doc """
  get argument :tanks -> if there are no UCTs in the list -> warn and create one by default
  """
  def change(changeset, _opts, _context) do
    tank_args = Ash.Changeset.get_argument(changeset, :tanks)

    process_tanks(tank_args, changeset)
  end

  def process_tanks(val, changeset) when val in [[], nil] do
    # create a default uct
    {:ok, tank} =
      Tank.create(%{
        location_type: :in_wh,
        capacity_type: :uncapped
      })

    Ash.Changeset.set_argument(changeset, :tanks, [tank])
  end

  def process_tanks(tank_args, changeset) when is_list(tank_args) do
    changeset =
      if Enum.any?(tank_args, fn
           %Tank{location_type: location_type} = _tank when location_type != :in_wh -> true
           _ -> false
         end) do
        Ash.Changeset.add_error(changeset,
          field: :tanks,
          message: """
          Expected: Warehouse cannot have a tank whose location_type is not `:in_wh`.
          Got: #{inspect(tank_args)}
          """
        )
      else
        changeset
      end

    # if given tank_args does not have any uct -> add one
    if Enum.any?(tank_args, fn
         # checking for uct
         %Tank{location_type: :in_wh, capacity_type: :uncapped} = _tank -> true
         _ -> false
       end)
       |> dbg() do
      changeset
    else
      # create a default uct
      {:ok, tank} =
        Tank.create(%{
          location_type: :in_wh,
          capacity_type: :uncapped
        })

      Ash.Changeset.set_argument(changeset, :tanks, [tank | tank_args])
    end
  end
end
