import PackageDescription

let package = Package(
    name: "Mesh",
    dependencies: [
		.Package(url: "https://github.com/randymarsh77/async", majorVersion: 1),
		.Package(url: "https://github.com/randymarsh77/bonjour", majorVersion: 1),
		.Package(url: "https://github.com/randymarsh77/streams", majorVersion: 0),
		.Package(url: "https://github.com/randymarsh77/sockets", majorVersion: 1),
	]
)
