defmodule Mplex.Stream do
  defstruct [
    :id,
    :initiator,
    :status,
    data_in: ""
  ]

  def read(%Mplex.Stream{data_in: data_in} = stream) do
    {%{stream | data_in: ""}, data_in}
  end
end