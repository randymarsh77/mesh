import Foundation
import Sockets

internal enum NodeAddress
{
	case Socket(EndpointAddress)
}

internal final class Node
{
	public let id: String
	public let address: NodeAddress

	init(id: String, address: NodeAddress)
	{
		self.id = id
		self.address = address
	}
}
