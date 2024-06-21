import ProjectDescription

let project = Project(
    name: "People",
    targets: [
        .target(
            name: "People",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.People",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen.storyboard",
                ]
            ),
            sources: ["People/Sources/**"],
            resources: ["People/Resources/**"],
            dependencies: [
              .external(name: "ComposableArchitecture"),
              .external(name: "GRDB")
            ]
        ),
        .target(
            name: "PeopleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.PeopleTests",
            infoPlist: .default,
            sources: ["People/Tests/**"],
            resources: [],
            dependencies: [.target(name: "People")]
        ),
    ]
)
