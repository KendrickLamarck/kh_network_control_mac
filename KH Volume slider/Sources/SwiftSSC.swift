//
//  SwiftSSC.swift
//  KH Volume slider
//
//  Created by Leander Blume on 25.03.25.
//
import Foundation
import Network

class SSCTransaction {
    var TX: String = ""
    var RX: String = ""
    var error: String = ""
}

class SSCDevice {
    var connection: NWConnection
    private let dispatchQueue: DispatchQueue

    enum SSCDeviceError: Error {
        case ipError
        case portError
        case sendError
        case receiveError
    }

    init?(ip: String, port: Int = 45) {
        guard let addr = IPv6Address(ip) else {
            return nil
        }
        let hostEndpoint = NWEndpoint.Host.ipv6(addr)
        guard let portEndpoint = NWEndpoint.Port(String(port)) else {
            return nil
        }
        let endpoint = NWEndpoint.hostPort(host: hostEndpoint, port: portEndpoint)
        connection = NWConnection(to: endpoint, using: .tcp)
        dispatchQueue = DispatchQueue(label: "KH Speaker connection")
    }

    init(endpoint: NWEndpoint) {
        connection = NWConnection(to: endpoint, using: .tcp)
        dispatchQueue = DispatchQueue(label: "KH Speaker connection")
    }

    static func scan(scanTime: UInt32 = 1) -> [SSCDevice] {
        var retval: [SSCDevice] = []
        let q = DispatchQueue(label: "KH Discovery")
        let browser = NWBrowser(
            for: .bonjour(type: "_ssc._tcp", domain: nil), using: .tcp)
        browser.browseResultsChangedHandler = { (results, changes) in
            for result in results {
                retval.append(SSCDevice(endpoint: (result.endpoint)))
            }
        }
        browser.start(queue: q)
        sleep(scanTime)
        return retval
    }

    func connect() {
        switch connection.state {
        case .ready, .preparing:
            return
        case .waiting:
            connection.restart()
        case .cancelled, .failed:
            connection = NWConnection(to: connection.endpoint, using: .tcp)
            connection.start(queue: dispatchQueue)
        default:
            connection.start(queue: dispatchQueue)
        }
    }

    func disconnect() {
        connection.cancel()
    }

    func sendMessage(_ TXString: String) -> SSCTransaction {
        let transaction = SSCTransaction()
        let sendCompHandler = NWConnection.SendCompletion.contentProcessed {
            error in
            if let error = error {
                transaction.error = String(describing: error)
                return
            }
            transaction.TX = TXString
        }
        let TXraw = TXString.appending("\r\n").data(using: .ascii)!
        connection.send(content: TXraw, completion: sendCompHandler)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 512) {
            (content, context, isComplete, error) in
            guard let content = content else {
                transaction.error = String(describing: error)
                return
            }
            transaction.RX = String(data: content, encoding: .utf8) ?? "No Response"
        }
        return transaction
    }
}
