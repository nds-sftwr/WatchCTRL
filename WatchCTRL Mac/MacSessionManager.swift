import Foundation
import MultipeerConnectivity
import Observation

struct RelayMessage: Codable {
    let type: String    // "gesture" or "anki_action"
    let action: String  // e.g. "scroll_down", "anki_1", "anki_space"
}

@Observable
class MacSessionManager: NSObject {
    static let shared = MacSessionManager()

    var isConnected = false
    var connectedDeviceName: String?
    var lastAction: String?
    var lastActionTime: Date?
    var isListening = true

    private let serviceType = "watchctrl"
    private let myPeerID: MCPeerID
    private var advertiser: MCNearbyServiceAdvertiser?
    private var session: MCSession?

    override init() {
        myPeerID = MCPeerID(displayName: Host.current().localizedName ?? "Mac")
        super.init()
        startListening()
    }

    func startListening() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        session?.delegate = self

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        isListening = true
    }

    func stopListening() {
        advertiser?.stopAdvertisingPeer()
        session?.disconnect()
        isListening = false
        isConnected = false
        connectedDeviceName = nil
    }

    private func handleMessage(_ data: Data) {
        guard let message = try? JSONDecoder().decode(RelayMessage.self, from: data) else { return }

        DispatchQueue.main.async {
            self.lastAction = message.action
            self.lastActionTime = Date()

            switch message.type {
            case "gesture":
                KeySimulator.executeGestureAction(message.action)
            case "anki_action":
                KeySimulator.executeAnkiAction(message.action)
            default:
                break
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MacSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to advertise: \(error.localizedDescription)")
    }
}

// MARK: - MCSessionDelegate

extension MacSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.isConnected = true
                self.connectedDeviceName = peerID.displayName
            case .notConnected:
                self.isConnected = false
                self.connectedDeviceName = nil
            case .connecting:
                break
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handleMessage(data)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
