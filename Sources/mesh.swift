import Foundation
import Async
import Bonjour
import Scope
import Sockets
import Streams

let MeshPort: UInt16 = 6374
let MeshServiceType: ServiceType = .Unregistered(identifier: "mesh")

public class Mesh
{
	public let nodeId = UUID().uuidString
	public var bonjourName: String { return "_mesh-node-\(nodeId)" }
	public var messageStream: ReadableStream<Message> { return ReadableStream(stream) }

	var stream = Streams.Stream<Message>()

	public init()
	{
	}

	public func activate()
	{
		if (server != nil) {
			return;
		}

		// listen and broadcast
		server = TCPServer(port: MeshPort) { (socket) in
			let peer = PeerHandshakeUtility.HandshakeIncoming(socket)
			self.add(peer)
		}
		let broadcastSettings = BroadcastSettings(name: bonjourName, serviceType: MeshServiceType, serviceProtocol: .TCP, domain: .AnyDomain, port: Int32(MeshPort))
		broadcastScope = Bonjour.Broadcast(broadcastSettings)

		// connect to all known peers (4 now)
		DispatchQueue.global().async {
			let querySettings = QuerySettings(serviceType: MeshServiceType, serviceProtocol: .TCP, domain: .AnyDomain)
			let services = await (Bonjour.FindAll(querySettings))
			for service in services {
				await (Bonjour.Resolve(service))
				if (service.name == self.bonjourName) {
					continue
				}

				let peer = self.connect(service)
				self.add(peer)
			}
		}
	}

	public func deactivate()
	{
		if (server == nil) {
			return;
		}

		broadcastScope?.dispose()
		server?.dispose()
		for peer in peers {
			peer.dispose()
		}
		peers = [Peer]()
	}

	public func notify(message: String)
	{
		for peer in peers {
			peer.send(message)
		}
	}

	private func add(_ peer: Peer?)
	{
		if (peer != nil) {
			DispatchQueue.main.async {
				self.peers.append(peer!)
				_ = peer!.messageStream.pipe(to: self.stream)
			}
		}
	}

	private func connect(_ service: NetService) -> Peer?
	{
		let endpoint = service.getEndpointAddress()!
		let client = TCPClient(endpoint: endpoint)
		let socket = try! client.tryConnect()!
		return PeerHandshakeUtility.HandshakeOutgoing(socket)
	}

	private var peers = [Peer]()
	private var broadcastScope: Scope?
	private var server: TCPServer?
}
