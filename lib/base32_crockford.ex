defmodule Base32Crockford do
  @moduledoc ~S"""
  Base32-Crockford: human and machine readable, compact, error resistant
  and pronounceable base-32 encoding.

  https://www.crockford.com/wrmg/base32.html
  """

  @doc ~S"""
  Encodes an integer number into base32-crockford encoded string.
  """
  @spec encode(integer, keyword) :: binary
  def encode(number, opts \\ []) when is_integer(number) do
    base10to32([], number)
    |> append_check_symbol(number, opts)
    |> to_string
  end

  defp base10to32([], 0), do: '0'
  defp base10to32(chars, 0), do: chars
  defp base10to32(chars, number) do
    reminder = rem(number, 32)
    chars = [enc(reminder) | chars]
    number = div(number, 32)
    base10to32(chars, number)
  end

  defp append_check_symbol(chars, number, opts) do
    if Keyword.get(opts, :check_symbol, false) do
      reminder = rem(number, 37)
      chars <> enc(reminder)
    else
      chars
    end
  end

  @doc ~S"""
  Decodes base32-crockford encoded string into integer number.
  """
  @spec decode(binary) :: {:ok, integer} | :error
  def decode(binary) when is_binary(binary) do
    values = binary
    |> String.upcase
    |> String.reverse
    |> String.to_charlist
    |> Enum.with_index
    |> Enum.map(&base32to10/1)
    case Enum.filter(values, &(&1 == :error)) do
      [] ->
        {:ok, Enum.sum(values)}
      _ -> :error
    end
  end

  defp base32to10({char, power}) do
    with {:ok, value} <- dec(char) do
      value * :math.pow(32, power) |> round
    end
  end

  alphabet = Enum.with_index('0123456789ABCDEFGHJKMNPQRSTVWXYZ*~$=U')
  for {encoding, value} <- alphabet do
    defp enc(unquote(value)), do: unquote(encoding)
    defp dec(unquote(encoding)), do: {:ok, unquote(value)}
  end
  defp dec(79), do: {:ok, 0} # O
  defp dec(73), do: {:ok, 1} # I
  defp dec(76), do: {:ok, 1} # L
  defp dec(_), do: :error
end
