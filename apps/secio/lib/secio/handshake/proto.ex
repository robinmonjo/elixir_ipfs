defmodule Secio.Handshake.Proto do
  use Protobuf, """
    message Propose {
      optional bytes rand = 1;
      optional bytes pubkey = 2;
      optional string exchanges = 3;
      optional string ciphers = 4;
      optional string hashes = 5;
    }

    enum KeyType {
      RSA = 0;
      Ed25519 = 1;
      Secp256k1 = 2;
    }

    message PublicKey {
      required KeyType Type = 1;
      required bytes Data = 2;
    }

    message PrivateKey {
      required KeyType Type = 1;
      required bytes Data = 2;
    }

    message Exchange {
      optional bytes epubkey = 1;
      optional bytes signature = 2;
    }
  """
end
