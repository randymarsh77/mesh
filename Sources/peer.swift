import Foundation
import IDisposable
import Sockets
import Streams

public struct Message
{
	public var source: String
	public var content: String
}

public final class Peer : IDisposable
{
	public var messageStream: ReadableStream<Message> { return ReadableStream(stream) }

	var socket: Socket
	var stream = Streams.Stream<Message>()

	fileprivate init(_ socket: Socket)
	{
		self.socket = socket
		DispatchQueue.global().async {
			let data = socket.read(1024)
			self.stream.publish(Message(source: "TODO", content: String(data: data!, encoding: .utf8)!))
		}
	}

	public func dispose()
	{
		socket.dispose()
	}
}

public extension Peer
{
	public func send(_ message: String)
	{
		socket.write(message.data(using: .utf8)!)
	}
}

public final class PeerHandshakeUtility
{
	public static func HandshakeIncoming(_ socket: Socket) -> Peer?
	{
		return Peer(socket)
	}

	public static func HandshakeOutgoing(_ socket: Socket) -> Peer?
	{
		return Peer(socket)
	}
}
