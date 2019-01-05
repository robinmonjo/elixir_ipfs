defmodule Secio.Handshake.Support do
  @exchanges %{
    "P-256" => :secp256r1,
    "P-384" => :secp384r1,
    "P-521" => :secp521r1
  }

  def exchanges, do: map_keys_str(@exchanges)
  def exchanges(key), do: Map.get(@exchanges, key)

  @ciphers %{
    "AES-256" => :aes_cbc256,
    "AES-128" => :aes_cbc128
  }

  def ciphers, do: map_keys_str(@ciphers)
  def ciphers(key), do: Map.get(@ciphers, key)

  def cipher_size("AES-128"), do: {16, 16}
  def cipher_size("AES-256"), do: {32, 16}

  @hashes %{
    "SHA256" => :sha256,
    "SHA512" => :sha512
  }

  def hashes, do: map_keys_str(@hashes)
  def hashes(key), do: Map.get(@hashes, key)

  def hash_size("SHA512"), do: 64
  def hash_size(:sha512), do: 64
  def hash_size("SHA256"), do: 32
  def hash_size(:sha256), do: 32

  defp map_keys_str(map) do
    map
    |> Map.keys()
    |> Enum.join(",")
  end
end
