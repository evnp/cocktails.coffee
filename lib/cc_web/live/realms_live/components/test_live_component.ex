defmodule CcWeb.RealmsLive.Components.TestLiveComponent do
  use CcWeb, :live_component

  def render(assigns) do
    temple do
      div do: "TEST LIVE COMPONENT CONTENT"
    end
  end
end
