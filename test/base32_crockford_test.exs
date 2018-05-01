defmodule Base32CrockfordTest do
  use ExUnit.Case
  doctest Base32Crockford
  import Base32Crockford

  describe "#encode" do
    test "encodes integer to base 32 string" do
      assert "0" == encode(0)
      assert "Z" == encode(31)
      assert "16J" == encode(1234)
      assert "1CZ" == encode(1439)
    end

    test "appends check symbol" do
      assert "00" == encode(0, checksum: true)
      assert "ZZ" == encode(31, checksum: true)
      assert "16JD" == encode(1234, checksum: true)
      assert "1CZ~" == encode(1439, checksum: true)
    end

    test "partions encoded string by hyphens" do
      assert "XS-NJ-G0" == encode(1_000_000_000, partitions: 3)
      assert "XSN-JG0" == encode(1_000_000_000, partitions: 2)
      assert "XSNJG0" == encode(1_000_000_000, partitions: 1)
    end
  end

  describe "#decode" do
    test "decodes base 32 encoded string to integer" do
      assert {:ok, 31} == decode("Z")
      assert {:ok, 1234} == decode("16J")
    end

    test "case insensitive" do
      assert {:ok, 31} == decode("z")
      assert {:ok, 1439} == decode("1cz")
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
      assert :error == decode("1CZ~")
    end

    test "checks encoded string with check symbol" do
      assert {:ok, 31} == decode("ZZ", checksum: true)
      assert {:ok, 1439} == decode("1CZ~", checksum: true)
    end

    test "returns error when wrong check symbol" do
      assert :error == decode("1CZ*", checksum: true)
    end

    test "ignores hyphens" do
      assert {:ok, 1_000_000_000} == decode("XS-NJ-G0")
    end
  end

  describe "#decode!" do
    test "decodes base 32 encoded string to integer" do
      assert 31 == decode!("Z")
      assert 1234 == decode!("16J")
    end

    test "raises ArgumentError for unsupported characters" do
      assert_raise ArgumentError, fn ->
        decode!("U")
      end
    end

    test "raises ArgumentError when wrong check symbol" do
      assert 1439 == decode!("1CZ~", checksum: true)
      assert_raise ArgumentError, fn ->
        decode!("1CZ*", checksum: true)
      end
    end
  end
end
