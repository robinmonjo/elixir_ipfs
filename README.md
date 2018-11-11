# ElixirIpfs


- First create a multiaddr project : https://github.com/multiformats/multiaddr
- Then the goal is to work with the DHT (https://en.wikipedia.org/wiki/Kademlia) of libp2p
  - some guy did it in go : https://github.com/joosep-wm/connect-to-dht/blob/master/main.go
  - that will imply :
    - create a peer module. The go version is here: https://github.com/libp2p/go-libp2p-peer. The JS version is divided in 2 classes: [PeerInfo](https://github.com/libp2p/js-peer-info) and [PeerId](https://github.com/libp2p/js-peer-id)
    - probable create a crypto app that will be used by other (all?) apps
    - create a transport abstraction (TCP only for now)
    - create the swarm, host or switch that handle the connection (dial listen interface) to a multi address (TCP only for now)
    -


