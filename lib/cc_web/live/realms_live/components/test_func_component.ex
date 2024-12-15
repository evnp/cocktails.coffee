defmodule CcWeb.RealmsLive.Components.TestFuncComponent do
  use CcWeb, :component

  def render(assigns) do
    temple do
      "TEST FUNCTION COMPONENT CONTENT"
    end
  end
end
