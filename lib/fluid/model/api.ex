defmodule Fluid.Model.Api do
  use Ash.Api

  resources do
    resource Fluid.Model.World
  end
end
