import Foundation
import Async
import Bonjour
import Scope
import Sockets
import Streams

let MeshServerOptions = ServerOptions(port: .Range(6300, 6400))
let MeshServiceType: ServiceType = .Unregistered(identifier: "_mesh")

public struct MeshSettings
{
	public init(name: String) {
		self.name = name
	}

	public let name: String
}

public class Mesh
{
	public let settings: MeshSettings
	public let nodeId = UUID().uuidString.replacingOccurrences(of: "-", with: "")
	public var bonjourName: String { return "\(settings.name)-\(nodeId)" }
	public var messageStream: ReadableStream<Message> { return ReadableStream(stream) }

	var stream = Streams.Stream<Message>()

	public init(settings: MeshSettings)
	{
		self.settings = settings
	}

	public func activate()
	{
		if (server != nil) {
			return;
		}

		// listen and broadcast
		server = try! TCPServer(options: MeshServerOptions) { (socket) in
			if let peer = PeerHandshakeUtility.HandshakeIncoming(socket, Node(id: "Unknown", address: .Socket(socket.address))) {
				self.add(peer)
			}
		}
		let broadcastSettings = BroadcastSettings(name: bonjourName, serviceType: MeshServiceType, serviceProtocol: .TCP, domain: .AnyDomain, port: Int32(server!.port))
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

				if let peer = self.connect(service) {
					self.add(peer)
				}
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
		peers = [ConnectedPeer]()
	}

	public func notify(message: String)
	{
		for peer in peers {
			peer.send(message)
		}
	}

	private func add(_ peer: ConnectedPeer)
	{
		DispatchQueue.main.async {
			self.peers.append(peer)
			_ = peer.messageStream.pipe(to: self.stream)
			_ = peer.messageStream.on { event in
				switch (event) {
				case .Disconnected:
					if let index = self.peers.index(where: { x in x === peer }) {
						self.peers.remove(at: index)
						peer.dispose()
					}
				}
			}
		}
	}

	private func connect(_ service: NetService) -> ConnectedPeer?
	{
		let endpoint = service.getEndpointAddress()!
		let client = TCPClient(endpoint: endpoint)
		let socket = try! client.tryConnect()!
		return PeerHandshakeUtility.HandshakeOutgoing(socket, Node(id: service.name, address: .Socket(socket.address)))
	}

	private var peers = [ConnectedPeer]()
	private var broadcastScope: Scope?
	private var server: TCPServer?
}
