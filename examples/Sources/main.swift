import Foundation
import Async
import Awaitables
import Mesh

var keepRunning = true
let mesh = Mesh(settings: MeshSettings(name: "TestMesh"))

mesh.activate()

_ = mesh.messageStream.subscribe { message in
	print("Message from \(message.source): \(message.content)")
}

DispatchQueue.global().async {
	_ = await (Signals(SIGINT))
	keepRunning = false
}

while (keepRunning) {
	mesh.notify(message: "Hello!")
	RunLoop.current.run(until: Date(timeIntervalSinceNow: 5.0))
}

mesh.deactivate()

print("Goodbye")
