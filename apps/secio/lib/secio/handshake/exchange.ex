defmodule Secio.Handshake.Exchange do
  alias Secio.Handshake.{Support, Proto}

  def start(socket, propose_state) do
    with {:ok, order, {p1, p2}} <- select_order(propose_state),
         {curve, cipher, hash} <- exchange_params(p1, p2),
         {e_pub, e_priv} <- ephemeral_keys(curve),
         signature <- signature(propose_state, e_pub),
         exchange <- exchange(e_pub, signature),
         exchange_bytes <- Proto.Exchange.encode(exchange),
         :ok <- :gen_tcp.send(socket, exchange_bytes),
         {:ok, exchange_in_bytes} <- :gen_tcp.recv(socket, 0),
         exchange_in <- Proto.Exchange.decode(exchange_in_bytes),
         signed_message <- signed_message(propose_state, exchange_in),
         pub <- remote_public_key_sequence(propose_state),
         :ok <- verify_signature(signed_message, pub, exchange_in),
         secret <- shared_secret(exchange_in, e_priv, curve) do
      %{
        secret: secret,
        order: order,
        cipher: cipher,
        hash: hash
      }
    end
  end

  defp select_order(%{propose: propose, propose_in: propose_in}) do
    local = :crypto.hash(:sha256, propose_in.pubkey <> propose.rand)
    remote = :crypto.hash(:sha256, propose.pubkey <> propose_in.rand)

    cond do
      local > remote -> {:ok, :local, {propose, propose_in}}
      remote > local -> {:ok, :remote, {propose_in, propose}}
      true -> {:error, :connecting_to_self}
    end
  end

  defp exchange_params(p1, p2) do
    {
      first_match(p1.exchanges, p2.exchanges),
      first_match(p1.ciphers, p2.ciphers),
      first_match(p1.hashes, p2.hashes)
    }
  end

  defp first_match(str1, str2) when is_binary(str1) and is_binary(str2) do
    first_match(String.split(str1, ","), String.split(str2, ","))
  end

  defp first_match(list1, list2) when is_list(list1) and is_list(list2) do
    Enum.find(list1, fn e1 ->
      Enum.find(list2, &(&1 == e1))
    end)
  end

  defp ephemeral_keys(curve), do: :crypto.generate_key(:ecdh, Support.exchanges(curve))

  defp signature(
         %{private_key: priv, propose_bytes: propose_bytes, propose_in_bytes: propose_in_bytes},
         e_pub
       ) do
    msg = propose_bytes <> propose_in_bytes <> e_pub
    :crypto.sign(:ecdsa, :sha256, msg, [priv, :secp256k1])
  end

  defp exchange(e_pub, signature), do: Proto.Exchange.new(epubkey: e_pub, signature: signature)

  defp signed_message(%{propose_bytes: p1, propose_in_bytes: p2}, exchange_in) do
    p2 <> p1 <> exchange_in.epubkey
  end

  defp remote_public_key_sequence(%{propose_in: propose_in}) do
    %Proto.PublicKey{Data: pub} = Proto.PublicKey.decode(propose_in.pubkey)
    {_, _, pub} = :public_key.der_decode(:SubjectPublicKeyInfo, pub)
    :public_key.der_decode(:RSAPublicKey, pub)
  end

  defp verify_signature(msg, pub, exchange_in) do
    if :public_key.verify(msg, :sha256, exchange_in.signature, pub) do
      :ok
    else
      {:error, :signature_mismatch}
    end
  end

  defp shared_secret(exchange_in, e_priv, curve) do
    priv = {:ECPrivateKey, 1, e_priv, {:namedCurve, Support.exchanges(curve)}, <<>>}
    pub = {:ECPoint, exchange_in.epubkey}
    :public_key.compute_key(pub, priv)
  end
end
