defmodule CcWeb.RoomComponents do
  use CcWeb, :component

  import CcWeb.CoreComponents

  attr :form, Phoenix.HTML.Form, required: true
  attr :target, :any, default: nil

  def room_form(assigns) do
    temple do
      c &simple_form/1,
        id: "room-form",
        for: @form,
        "phx-change": "validate-room",
        "phx-submit": "save-room",
        "phx-target": @target do
        slot :actions do
          c &button/1, "phx-disable-with": "Saving...", class: "w-full", do: "Save"
        end

        c &input/1,
          field: @form[:name],
          type: "text",
          label: "Name",
          "phx-debounce": true

        c &input/1,
          field: @form[:topic],
          type: "text",
          label: "Topic",
          "phx-debounce": true
      end
    end
  end
end
