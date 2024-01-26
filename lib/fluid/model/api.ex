defmodule Fluid.Model.Api do
  use Ash.Api

  resources do
    resource Fluid.Model.World
    resource Fluid.Model.Tank
    resource Fluid.Model.Warehouse
    resource Fluid.Model.Pool
    resource Fluid.Model.Tag
  end
end
