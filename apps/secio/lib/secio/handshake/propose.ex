defmodule Secio.Handshake.Propose do
  alias Secio.Handshake.{Support, Proto}
  alias Proto.Propose

  @nonce_size 16

  def start(socket) do
    with {pub, priv, nonce} <- init_state(),
         propose <- propose(pub, nonce),
         propose_bytes <- Propose.encode(propose),
         {:ok, _socket} <- Conn.write(socket, propose_bytes),
         {:ok, _socket, propose_in_bytes} <- Conn.read(socket),
         propose_in <- Propose.decode(propose_in_bytes) do
      {:ok,
       %{
         public_key: pub,
         private_key: priv,
         nonce: nonce,
         propose: propose,
         propose_bytes: propose_bytes,
         propose_in: propose_in,
         propose_in_bytes: propose_in_bytes
       }}
    else
      err -> err
    end
  end

  defp init_state do
    {pub, priv} = :crypto.generate_key(:ecdh, :secp256k1)
    nonce = :crypto.strong_rand_bytes(@nonce_size)
    {pub, priv, nonce}
  end

  defp propose(pub, nonce) do
    Propose.new(
      rand: nonce,
      pubkey: encode_pub(pub),
      exchanges: Support.exchanges(),
      ciphers: Support.ciphers(),
      hashes: Support.hashes()
    )
  end

  defp encode_pub(pub) do
    Proto.PublicKey.new(Type: 2, Data: pub)
    |> Proto.PublicKey.encode()
  end
end
