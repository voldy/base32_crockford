defmodule Base32CrockfordTest do
  use ExUnit.Case
  doctest Base32Crockford
  import Base32Crockford

  describe "#encode" do
    test "encodes integer to base 32 string" do
      assert "0" == encode(0)
      assert "Z" == encode(31)
      assert "16J" == encode(1234)
    end

    test "appends check symbol" do
      assert "00" == encode(0, check_symbol: true)
      assert "Z0" == encode(31, check_symbol: true)
      assert "16JD" == encode(1234, check_symbol: true)
      assert "16J~" == encode(1254, check_symbol: true)
    end
  end

  describe "#decode" do
    test "decodes base 32 encoded string to integer" do
      assert {:ok, 31} == decode("Z")
      assert {:ok, 1234} == decode("16J")
    end

    test "case insensitive" do
      assert {:ok, 31} == decode("z")
    end

    test "error resistant" do
      assert {:ok, 0} == decode("O")
      assert {:ok, 1} == decode("I")
      assert {:ok, 1} == decode("l")
    end

    test "returns error for unsupported characters" do
      assert :error == decode("U")
      assert :error == decode("FU")
      assert {:ok, _} = decode("BAR")
    end
  end
end
