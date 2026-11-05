"""Run the production coordinator against controlled connections without an iOS build."""

import pathlib
import subprocess
import tempfile
import unittest


class ManagementLifecycleTest(unittest.TestCase):
    def test_coordinator(self):
        root = pathlib.Path(__file__).resolve().parents[2]
        source = (root / "ios/Management/ManagementManager.swift").read_text()
        coordinator = source[source.index("actor UsbCoordinator {") :]
        fixtures = r"""
import Foundation

struct DeviceInfo: Sendable {}
enum SmartCardConnectionError: Error, Equatable {
    case cancelled, cancelledByUser, connectionLost, setupFailed
}
protocol SmartCardConnection: Sendable {
    func close(error: Error?) async
    func waitUntilClosed() async -> Error?
}
actor FakeConnection: SmartCardConnection {
    var closes = 0
    var failedCloses = 0
    var successMessages = 0
    private var closed = false
    private var waiter: CheckedContinuation<Error?, Never>?
    func close(error: Error?) async {
        closes += 1
        if error != nil { failedCloses += 1 }
        closed = true
        waiter?.resume(returning: error)
        waiter = nil
    }
    func waitUntilClosed() async -> Error? {
        if closed { return nil }
        return await withCheckedContinuation { waiter = $0 }
    }
}
typealias NFCSmartCardConnection = FakeConnection
extension FakeConnection {
    static func makeConnection(alertMessage: String) async throws -> FakeConnection {
        await Connections.shared.openNfc()
    }
    func close(message: String) async {
        successMessages += 1
        await close(error: nil)
    }
}
actor Connections {
    static let shared = Connections()
    var wiredOpens = 0
    var nfcOpens = 0
    var failMetadata = false
    var failDiscovery = false
    var available = true
    let discoveryFailed = Signal()
    let presenceChecked = Signal()
    func simulateRemovalRace() { failDiscovery = true; available = false }
    func devices() async -> [Int] {
        await presenceChecked.send()
        return available ? [1] : []
    }
    func setMetadataFailure() { failMetadata = true }
    func clearMetadataFailure() { failMetadata = false }
    func readMetadata() throws -> DeviceInfo {
        if failMetadata { throw SmartCardConnectionError.connectionLost }
        return DeviceInfo()
    }
    func openWired() async throws -> FakeConnection {
        wiredOpens += 1
        if failDiscovery {
            await discoveryFailed.send()
            throw SmartCardConnectionError.setupFailed
        }
        return FakeConnection()
    }
    func openNfc() -> FakeConnection {
        nfcOpens += 1
        return FakeConnection()
    }
}
enum WiredSmartCardConnection {
    static func makeConnection() async throws -> any SmartCardConnection {
        try await Connections.shared.openWired()
    }
}
typealias USBSmartCardConnection = FakeConnection
extension FakeConnection {
    static func availableDevices() async throws -> [Int] {
        await Connections.shared.devices()
    }
}
enum ManagementManager {
    static func readDeviceInfo(from connection: any SmartCardConnection) async throws -> DeviceInfo {
        try await Connections.shared.readMetadata()
    }
}
enum ManagementTargetError: Error { case wiredDeviceUnavailable }
actor Signal {
    private var signalled = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    func send() {
        signalled = true
        for waiter in waiters { waiter.resume() }
        waiters.removeAll()
    }
    func wait() async {
        if signalled { return }
        await withCheckedContinuation { waiters.append($0) }
    }
}
@MainActor final class Outcome {
    var failure: Error?
    func capture(_ body: () async throws -> Void) async {
        do { try await body() } catch { failure = error }
    }
}
"""
        tests = r"""
@main struct Tests {
    @MainActor static func main() async throws {
        let coordinator = UsbCoordinator()
        let attached = Signal()
        let monitor = Task {
            await coordinator.startMonitoring(
                onAttach: { _ in await attached.send() },
                onDetach: {},
                onError: { _ in fatalError("Unexpected monitor failure") }
            )
        }
        await attached.wait()
        let outcome = Outcome()
        var first: FakeConnection?
        for _ in 0..<2 {
            try await coordinator.performOperation {
                await outcome.capture {
                    try await coordinator.withWiredConnection(reconnect: false) { connection in
                        guard let fake = connection as? FakeConnection else { fatalError() }
                        await MainActor.run {
                            if let first { precondition(first === fake) } else { first = fake }
                        }
                    }
                }
            }
        }
        precondition(outcome.failure == nil)
        let opens = await Connections.shared.wiredOpens
        let closes = await first!.closes
        precondition(opens == 1 && closes == 0, "Normal operations must reuse the connection")

        let failed = Outcome()
        try await coordinator.performOperation {
            await failed.capture {
                try await coordinator.withWiredConnection(reconnect: false) { _ in
                    throw CancellationError()
                }
            }
        }
        precondition(failed.failure is CancellationError)
        let afterFailureCloses = await first!.closes
        precondition(afterFailureCloses == 0, "Operation failure must not close the shared connection")

        let started = Signal()
        let release = Signal()
        let pending = Task {
            try await coordinator.performOperation {
                await started.send()
                await release.wait()
            }
        }
        await started.wait()
        do {
            try await coordinator.performOperation { fatalError("Concurrent operation executed") }
            fatalError("Concurrent request accepted")
        } catch ManagementOperationError.alreadyInProgress {}
        let stillPresent = await coordinator.hasWiredDevice
        precondition(stillPresent, "Operation must not hide the wired connection")
        await release.send()
        try await pending.value

        try await coordinator.performOperation {
            await outcome.capture {
                try await coordinator.withWiredConnection(reconnect: true) { _ in }
            }
        }
        for _ in 0..<100 {
            if await Connections.shared.wiredOpens == 2 { break }
            await Task.yield()
        }
        let rebootOpens = await Connections.shared.wiredOpens
        precondition(rebootOpens == 2, "Reboot must reconnect the monitor")

        let nfcFailure = Outcome()
        var failedNfc: FakeConnection?
        try await coordinator.performOperation {
            await nfcFailure.capture {
                try await coordinator.withNFCConnection(successMessage: "Done") { connection in
                    await MainActor.run { failedNfc = connection }
                    throw SmartCardConnectionError.connectionLost
                }
            }
        }
        let failureCloses = await failedNfc!.failedCloses
        let failureSuccessMessages = await failedNfc!.successMessages
        precondition(failureCloses == 1 && failureSuccessMessages == 0,
                     "NFC failure must close as an error, not success")

        let nfcStarted = Signal()
        let nfcOutcome = Outcome()
        let nfcTask = Task {
            try await coordinator.performOperation {
                await nfcOutcome.capture {
                    try await coordinator.withNFCConnection(successMessage: "Done") { connection in
                        await nfcStarted.send()
                        _ = await connection.waitUntilClosed()
                        try Task.checkCancellation()
                    }
                }
            }
        }
        await nfcStarted.wait()
        do {
            try await coordinator.performOperation { fatalError("USB request bypassed NFC guard") }
            fatalError("Concurrent USB request accepted")
        } catch ManagementOperationError.alreadyInProgress {}
        monitor.cancel()
        await coordinator.stop()
        try await nfcTask.value
        await monitor.value
        precondition(nfcOutcome.failure is CancellationError)
        let stoppedPresent = await coordinator.hasWiredDevice
        precondition(!stoppedPresent)
        do {
            try await coordinator.performOperation { fatalError("Stopped manager executed operation") }
            fatalError("Stopped manager accepted request")
        } catch ManagementOperationError.alreadyInProgress {}
        precondition(ManagementOperationError.isCancellation(SmartCardConnectionError.cancelled))
        precondition(ManagementOperationError.isCancellation(SmartCardConnectionError.cancelledByUser))
        precondition(ManagementOperationError.isCancellation(CancellationError()))
        precondition(!ManagementOperationError.isCancellation(SmartCardConnectionError.connectionLost))

        await Connections.shared.setMetadataFailure()
        let failureReported = Signal()
        let failingCoordinator = UsbCoordinator()
        let failingMonitor = Task {
            await failingCoordinator.startMonitoring(
                onAttach: { _ in fatalError("Failed read published a key") },
                onDetach: {},
                onError: { error in
                    precondition(error as? SmartCardConnectionError == .connectionLost)
                    await failureReported.send()
                }
            )
        }
        await failureReported.wait()
        failingMonitor.cancel()
        await failingCoordinator.stop()
        await failingMonitor.value
        await Connections.shared.clearMetadataFailure()
        let detachedCoordinator = UsbCoordinator()
        let removalAttached = Signal()
        let detachedMonitor = Task {
            await detachedCoordinator.startMonitoring(
                onAttach: { _ in await removalAttached.send() },
                onDetach: {},
                onError: { _ in fatalError("USB removal reported as access failure") }
            )
        }
        await removalAttached.wait()
        await Connections.shared.simulateRemovalRace()
        try await detachedCoordinator.performOperation {
            await outcome.capture {
                try await detachedCoordinator.withWiredConnection(reconnect: false) { connection in
                    await connection.close(error: nil)
                }
            }
        }
        await Connections.shared.discoveryFailed.wait()
        await Connections.shared.presenceChecked.wait()
        detachedMonitor.cancel()
        await detachedCoordinator.stop()
        await detachedMonitor.value
        print("Lifecycle scenarios passed: reuse, global exclusion, reboot, cancellation, shutdown")
    }
}
"""
        with tempfile.TemporaryDirectory(prefix="management-lifecycle-") as directory:
            path = pathlib.Path(directory)
            swift = path / "test.swift"
            swift.write_text(fixtures + coordinator + tests)
            executable = path / "test"
            subprocess.run(
                ["swiftc", "-parse-as-library", str(swift), "-o", str(executable)],
                check=True,
                timeout=60,
            )
            subprocess.run([str(executable)], check=True, timeout=20)


if __name__ == "__main__":
    unittest.main()
