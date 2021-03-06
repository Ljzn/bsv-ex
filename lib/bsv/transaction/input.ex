defmodule BSV.Transaction.Input do
  @moduledoc """
  Module for parsing and serialising transaction inputs.
  """
  alias BSV.Script
  alias BSV.Transaction.Output
  alias BSV.Util
  alias BSV.Util.VarBin

  defstruct output_txid: nil,
            output_index: 0,
            script: nil,
            sequence: 0,
            utxo: nil

  @typedoc "Transaction input"
  @type t :: %__MODULE__{
    output_txid: String.t,
    output_index: integer,
    script: binary,
    sequence: integer,
    utxo: Output.t
  }

  @max_sequence 0xFFFFFFFF

  @p2pkh_script_size 108


  @doc """
  Parse the given binary into a transaction input. Returns a tuple containing
  the transaction input and the remaining binary data.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.Input.parse(data)
      {%BSV.Trasaction.Input{}, ""}
  """
  @spec parse(binary, keyword) :: {__MODULE__.t, binary}
  def parse(data, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    <<txid::bytes-32, index::little-32, data::binary>> = data
    |> Util.decode(encoding)
    {script, data} = VarBin.parse_bin(data)
    <<sequence::little-32, data::binary>> = data

    {struct(__MODULE__, [
      output_txid: txid |> Util.reverse_bin |> Util.encode(:hex),
      output_index: index,
      script: Script.parse(script),
      sequence: sequence
    ]), data}
  end


  @doc """
  Serialises the given transaction input struct into a binary.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.Input.serialize(input)
      <<binary>>
  """
  @spec serialize(__MODULE__.t, keyword) :: binary
  def serialize(%__MODULE__{} = input, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    txid = input.output_txid
    |> Util.decode(:hex)
    |> Util.reverse_bin

    script = case input.script do
      %Script{} = s -> Script.serialize(s) |> VarBin.serialize_bin
      _ -> <<>>
    end

    <<
      txid::binary,
      input.output_index::little-32,
      script::binary,
      input.sequence::little-32
    >>
    |> Util.encode(encoding)
  end


  @doc """
  Returns the size of the given input. If the input has a script, it's actual
  size is calculated, otherwise a P2PKH input is estimated.
  """
  @spec get_size(__MODULE__.t) :: integer
  def get_size(%__MODULE__{script: script} = tx) do
    case script do
      nil -> 40 + @p2pkh_script_size
      %Script{chunks: []} -> 40 + @p2pkh_script_size
      _ -> serialize(tx) |> byte_size
    end
  end
  
end