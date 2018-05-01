defmodule Base32Crockford do
  @moduledoc ~S"""
  Base32-Crockford:  base-32 encoding for expressing integer numbers
  in a form that can be conveniently and accurately transmitted
  between humans and computer systems.

  https://www.crockford.com/wrmg/base32.html
  """

  @doc ~S"""
  Encodes an integer number into base32-crockford encoded string.

  ## Examples

      iex> Base32Crockford.encode(1_000_000_000)
      "XSNJG0"

      iex> Base32Crockford.encode(1_000_000_000, partition_length: 2)
      "XS-NJ-G0"

      iex> Base32Crockford.encode(1_000_000_000, partition_length: 3)
      "XSN-JG0"

      iex> Base32Crockford.encode(32, check_symbol: true)
      "10*"
  """
  @spec encode(integer, keyword) :: binary
  def encode(number, opts \\ []) when is_integer(number) do
    init_encoding(number, opts)
    |> base10to32(number)
    |> to_string
    |> partition(opts)
  end

  @doc ~S"""
  Decodes base32-crockford encoded string into integer number.

  ## Examples

      iex> Base32Crockford.decode("XSNJG0")
      {:ok, 1000000000}

      iex> Base32Crockford.decode("XSN-JG0")
      {:ok, 1000000000}

      iex> Base32Crockford.decode("10*", check_symbol: true)
      {:ok, 32}

      iex> Base32Crockford.decode("10~", check_symbol: true)
      :error
  """
  @spec decode(binary, keyword) :: {:ok, integer} | :error
  def decode(binary, opts \\ []) when is_binary(binary) do
    {chars, check_symbol} = binary
    |> String.replace("-", "")
    |> String.upcase
    |> String.reverse
    |> String.to_charlist
    |> init_decoding(opts)

    values = chars
    |> Enum.with_index
    |> Enum.map(&base32to10/1)

    case Enum.filter(values, &(&1 == :error)) do
      [] ->
        Enum.sum(values)
        |> check(check_symbol)
      _ -> :error
    end
  end

  defp init_encoding(number, opts) do
    if Keyword.get(opts, :check_symbol, false) do
      [calculate_check_symbol(number)]
    else
      []
    end
  end

  defp init_decoding(chars, opts) do
    if Keyword.get(opts, :check_symbol, false) do
      [check_symbol | chars] = chars
      {chars, check_symbol}
    else
      {chars, nil}
    end
  end

  defp base10to32([], 0), do: '0'
  defp base10to32('0', 0), do: '00'
  defp base10to32(chars, 0), do: chars
  defp base10to32(chars, number) do
    reminder = rem(number, 32)
    chars = [enc(reminder) | chars]
    number = div(number, 32)
    base10to32(chars, number)
  end

  defp base32to10({char, power}) do
    with {:ok, value} <- dec(char) do
      value * :math.pow(32, power) |> round
    end
  end

  defp check(number, nil), do: {:ok, number}
  defp check(number, check_symbol) do
    case calculate_check_symbol(number) do
      ^check_symbol ->
        {:ok, number}
      _ -> :error
    end
  end

  defp partition(binary, opts) do
    case Keyword.get(opts, :partition_length, 0) do
      0 -> binary
      len ->
        split([], binary, len)
        |> Enum.reverse
        |> Enum.join("-")
    end
  end

  defp split(parts, binary, len) do
    {part, rest} = String.split_at(binary, len)
    parts = [part | parts]
    if String.length(rest) > len do
      split(parts, rest, len)
    else
      [rest | parts]
    end
  end

  defp calculate_check_symbol(number) do
    reminder = rem(number, 37)
    enc(reminder)
  end

  encoding_symbols = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
  check_symbols = '*~$=U'
  encoding_alphabet = Enum.with_index(encoding_symbols ++ check_symbols)
  for {encoding, value} <- encoding_alphabet do
    defp enc(unquote(value)), do: unquote(encoding)
  end
  decoding_alphabet = Enum.with_index(encoding_symbols)
  for {encoding, value} <- decoding_alphabet do
    defp dec(unquote(encoding)), do: {:ok, unquote(value)}
  end
  defp dec(79), do: {:ok, 0} # O
  defp dec(73), do: {:ok, 1} # I
  defp dec(76), do: {:ok, 1} # L
  defp dec(_), do: :error
end
