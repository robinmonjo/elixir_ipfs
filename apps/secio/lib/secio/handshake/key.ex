defmodule Secio.Handshake.Key do
  alias Secio.Handshake.Support

  @seed "key expansion"
  @hmac_key_size 20

  def compute(exchange_state) do
    with {k1, k2} <- stretch_key(exchange_state),
         {locale_key, remote_key} <- attribute_key(k1, k2, exchange_state) do
      %{
        locale_key: locale_key,
        remote_key: remote_key
      }
    end
  end

  defp stretch_key(%{secret: secret, cipher: cipher, hash: hash}) do
    {key_size, iv_size} = Support.cipher_size(cipher)
    hash = Support.hashes(hash)

    cur = :crypto.hmac(hash, secret, @seed)

    size = 2 * (iv_size + key_size + @hmac_key_size)

    k = stretch(hash, secret, cur, size)

    half = div(size, 2)

    <<k1::bytes-size(half), k2::bytes-size(half), _::binary>> = k
    <<k1_iv::bytes-size(iv_size), k1_cipher_key::bytes-size(key_size), k1_mac_key::binary>> = k1
    <<k2_iv::bytes-size(iv_size), k2_cipher_key::bytes-size(key_size), k2_mac_key::binary>> = k2

    {{k1_iv, k1_cipher_key, k1_mac_key}, {k2_iv, k2_cipher_key, k2_mac_key}}
  end

  defp stretch(hash, secret, cur, size, acc \\ <<>>)
  defp stretch(_hash, _secret, _cur, size, acc) when byte_size(acc) >= size - 1, do: acc

  defp stretch(hash, secret, cur, size, acc) do
    s = :crypto.hmac(hash, secret, cur <> @seed)
    next = :crypto.hmac(hash, secret, cur)
    stretch(hash, secret, next, size, acc <> s)
  end

  defp attribute_key(k1, k2, %{order: :local}), do: {k2, k1}
  defp attribute_key(k1, k2, %{order: :remote}), do: {k1, k2}
end
