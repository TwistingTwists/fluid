defmodule Fluid.Error.RepoError do
  @moduledoc """
  Unwrap all the repo errors in this module

  :target - the target module which results in error
  :class - allows to customise the class of errors. :create_error, :read_error, :update_error, :delete_error
  """
  use Fluid.Error.Exception

  def_error([:error, :target], class: :create_error)

  defimpl Fluid.ErrorKind do
    def message(%{error: error}) do
      if is_binary(error) do
        to_string(error)
      else
        inspect(error)
      end
    end
  end
end
