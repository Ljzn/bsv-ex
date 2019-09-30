defmodule BSV.Transaction.Output do
  @moduledoc """
  Module for parsing and serialising transaction outputs.
  """
  alias BSV.Transaction.Script
  alias BSV.Util
  alias BSV.Util.VarBin

  defstruct satoshis: 0, amount: 0, script: nil

  @typedoc "Transaction output"
  @type t :: %__MODULE__{
    satoshis: integer,
    amount: float,
    script: binary
  }


  @doc """
  Parse the given binary into a single transaction output. Returns a tuple
  containing the transaction output and the remaining binary data.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.Output.parse(data)
      {%BSV.Trasaction.Output{}, ""}
  """
  @spec parse(binary, keyword) :: {__MODULE__.t, binary}
  def parse(data, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    <<satoshis::little-64, data::binary>> = data
    |> Util.decode(encoding)
    {script, data} = VarBin.parse_bin(data)

    {struct(__MODULE__, [
      satoshis: satoshis,
      amount: satoshis * 0.00000001,
      script: Script.parse(script)
    ]), data}
  end


  @doc """
  Serialises the given transaction output struct into a binary.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.Output.serialize(output)
      <<binary>>
  """
  @spec serialize(__MODULE__.t, keyword) :: binary
  def serialize(%__MODULE__{} = output, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    script = output.script
    |> Script.serialize
    |> VarBin.serialize_bin

    <<output.satoshis::little-64, script::binary>>
    |> Util.encode(encoding)
  end

end