defmodule Fluid.Model.Warehouse.Changes.AddDefaultUCT do
  use Ash.Resource.Change

  alias Fluid.Model.Tank
  # import Helpers.ColorIO
  require Logger

  @doc """
  get argument :tanks -> if there are no UCTs in the list -> warn and create one by default

  :arg = argument taken by ash from model api
  :rel = the relationship to manage. for warehouse, that will be :tanks
  """
  def change(changeset, opts, _context) do
    tank_arg_atom = opts[:arg] || :tanks
    # tank_rel_atom = opts[:rel] || :tanks

    tank_args =
      Ash.Changeset.get_argument(changeset, tank_arg_atom)
      # to ensure that we always have a list of tanks
      |> List.wrap()

    process_tanks(tank_args, changeset, opts)
  end

  # special case for adding capped tank -> because we need to add a default UCT too.

  def process_tanks(val, changeset, opts) when val in [[], nil] do
    tank_rel_atom = opts[:rel] || :tanks

    # create a default uct
    {:ok, tank} =
      Tank.create(%{
        location_type: :in_wh,
        capacity_type: :uncapped
      })

    Ash.Changeset.set_argument(changeset, tank_rel_atom, [tank])
  end

  def process_tanks(tank_args, changeset, opts) when is_list(tank_args) do
    tank_rel_atom = opts[:rel] || :tanks

    changeset =
      if Enum.any?(tank_args, fn
           %Tank{location_type: location_type} = _tank when location_type != :in_wh -> true
           _ -> false
         end) do
        Ash.Changeset.add_error(changeset,
          field: tank_rel_atom,
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
       end) do
      changeset
    else
      # create a default uct
      {:ok, tank} =
        Tank.create(%{
          location_type: :in_wh,
          capacity_type: :uncapped
        })

      # add existing tanks from the data
      # ([tank] ++ tank_args ++ changeset.data.tanks)
      all_tanks =
        [tank] ++ tank_args

      # |> green("#{__MODULE__}")

      Ash.Changeset.set_argument(changeset, tank_rel_atom, all_tanks)
    end
  end
end
