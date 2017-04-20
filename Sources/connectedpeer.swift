import Foundation
import IDisposable
import Sockets
import Streams

public enum PeerEvent
{
	case Disconnected
}

public struct Message
{
	public var source: String
	public var content: String
}

internal final class ConnectedPeer : IDisposable
{
	public var messageStream: ReadableEventingStream<PeerEvent, Message> { return ReadableEventingStream(stream) }

	var socket: Socket
	var stream: EventingStream<PeerEvent, Message> = Streams.Stream<Message>().asEventing()

	fileprivate init(_ socket: Socket, _ node: Node)
	{
		self.socket = socket
		DispatchQueue.global().async {
			while self.socket.isValid, let data = self.socket.read(maxBytes: 1024) {
				self.stream.publish(Message(source: node.id, content: String(data: data, encoding: .utf8)!))
			}
			self.stream.raise(.Disconnected)
		}
	}

	public func dispose()
	{
		socket.dispose()
	}
}

internal extension ConnectedPeer
{
	internal func send(_ message: String)
	{
		socket.write(message.data(using: .utf8)!)
	}
}

internal final class PeerHandshakeUtility
{
	public static func HandshakeIncoming(_ socket: Socket, _ node: Node) -> ConnectedPeer?
	{
		return ConnectedPeer(socket, node)
	}

	public static func HandshakeOutgoing(_ socket: Socket, _ node: Node) -> ConnectedPeer?
	{
		return ConnectedPeer(socket, node)
	}
}
