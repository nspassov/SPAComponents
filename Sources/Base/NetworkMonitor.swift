import Network
import Combine

@MainActor
public class NetworkMonitor: ObservableObject {
    @Published public private(set) var status: NWPath.Status

    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "NWPathMonitor")

    public init() {
        self.status = .satisfied
        
        pathMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                if path.status != self.status {
                    self.status = path.status
                }
            }
        }
        pathMonitor.start(queue: pathMonitorQueue)
    }
}
