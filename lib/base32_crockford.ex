defmodule Base32Crockford do
  @moduledoc ~S"""
  Base32-Crockford: base-32 encoding for expressing integer numbers
  in a form that can be conveniently and accurately transmitted
  between humans and computer systems.

  [https://www.crockford.com/wrmg/base32.html](https://www.crockford.com/wrmg/base32.html)

  A symbol set of 10 digits and 22 letters is used:
  `0123456789ABCDEFGHJKMNPQRSTVWXYZ`
  It does not include 4 of the 26 letters: I L O U.

  A check symbol can be appended to a symbol string. 5 additional symbols
  `*~$=U` are used only for encoding or decoding the check symbol.

  When decoding, upper and lower case letters are accepted,
  and i and l will be treated as 1 and o will be treated as 0.
  When encoding, only upper case letters are used.
  """

  @doc ~S"""
  Encodes an integer number into base32-crockford encoded string.

  Checksum can be added to the end of the string if the
  `:checksum` option is set to true.

  For better readability the resulting string can be partitioned by hyphens
  if the `:partitions` option is provided.

  ## Options

    * `:checksum` (boolean) - the check symbol will be added to the end
    of the string. The check symbol encodes the number modulo 37,
    37 being the least prime number greater than 32.

    * `:partitions` (positive integer) - hyphens (-) will be inserted into
    symbol strings to partition a string into manageable pieces,
    improving readability by helping to prevent confusion.

  ## Examples

      iex> Base32Crockford.encode(973_113_317)
      "X011Z5"

  To add a check symbol to the end of the string:

      iex> Base32Crockford.encode(973_113_317, checksum: true)
      "X011Z5$"

  To partition a resulting string into pieces:

      iex> Base32Crockford.encode(973_113_317, partitions: 2)
      "X01-1Z5"

      iex> Base32Crockford.encode(973_113_317, partitions: 3)
      "X0-11-Z5"

      iex> Base32Crockford.encode(973_113_317, partitions: 4)
      "X-0-11-Z5"
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

  Upper and lower case letters are accepted, and i and l will be treated as 1
  and o will be treated as 0.

  Hyphens are ignored during decoding.

  ## Options

    * `:checksum` (boolean) - the last symbol will be considered as check symbol
    and extracted from the encoded string before decoding. It then will be
    compared with a check symbol calculated from a decoded number.

  ## Examples

      iex> Base32Crockford.decode("X011Z5")
      {:ok, 973113317}

      iex> Base32Crockford.decode("XoIlZ5")
      {:ok, 973113317}

      iex> Base32Crockford.decode("X01-1Z5")
      {:ok, 973113317}

      iex> Base32Crockford.decode("X011Z5$", checksum: true)
      {:ok, 973113317}

      iex> Base32Crockford.decode("X011Z5=", checksum: true)
      :error
  """
  @spec decode(binary, keyword) :: {:ok, integer} | :error
  def decode(binary, opts \\ []) when is_binary(binary) do
    {chars, checksum} = binary
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
        |> check(checksum)
      _ -> :error
    end
  end

  @doc ~S"""
  Similar to `decode/2` but raises `ArgumentError` if a checksum is invalid or
  an invalid character is present in the string.

  ## Options

  Accepts the same options as `decode/2`.

  ## Examples

      iex> Base32Crockford.decode!("X011Z5")
      973113317
  """
  @spec decode!(binary, keyword) :: integer
  def decode!(binary, opts \\ []) when is_binary(binary) do
    case decode(binary, opts) do
      {:ok, number} -> number
      :error ->
        raise ArgumentError, "contains invalid character or checksum does not match"
    end
  end


  defp init_encoding(number, opts) do
    if Keyword.get(opts, :checksum, false) do
      [calculate_checksum(number)]
    else
      []
    end
  end

  defp init_decoding(chars, opts) do
    if Keyword.get(opts, :checksum, false) do
      [checksum | chars] = chars
      {chars, checksum}
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
  defp check(number, checksum) do
    case calculate_checksum(number) do
      ^checksum ->
        {:ok, number}
      _ -> :error
    end
  end

  defp partition(binary, opts) do
    case Keyword.get(opts, :partitions, 0) do
      count when count in [0, 1] ->
        binary
      count ->
        split([], binary, count)
        |> Enum.reverse
        |> Enum.join("-")
    end
  end

  defp split(parts, binary, 1), do: [binary | parts]
  defp split(parts, binary, count) do
    len = div(String.length(binary), count)
    {part, rest} = String.split_at(binary, len)
    split([part | parts], rest, count - 1)
  end

  defp calculate_checksum(number) do
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
