import PackageDescription

let package = Package(
    name: "examples",
    dependencies: [
		.Package(url: "..", majorVersion: 0),
		.Package(url: "https://github.com/randymarsh77/awaitables", majorVersion: 0),
	]
)
