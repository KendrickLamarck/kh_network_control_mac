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

struct SSCDevice {
    let ip: String
    let port: Int
    private let connection: NWConnection
    private let dispatchQueue: DispatchQueue

    enum SSCDeviceError: Error {
        case ipError
        case portError
        case sendError
        case receiveError
    }

    init?(ip ip_: String, port port_: Int = 45) {
        ip = ip_
        port = port_
        guard let addr = IPv6Address(ip) else {
            return nil
        }
        let hostEndpoint = NWEndpoint.Host.ipv6(addr)
        guard let portEndpoint = NWEndpoint.Port(String(port)) else {
            return nil
        }
        connection = NWConnection(host: hostEndpoint, port: portEndpoint, using: .tcp)
        dispatchQueue = DispatchQueue(label: "KH Speaker connection")
    }

    static func scan() -> [[String: String]] {
        var retval: [[String: String]] = []
        let q = DispatchQueue(label: "KH Discovery")
        let browser = NWBrowser(
            for: .bonjour(type: "_ssc._tcp", domain: nil), using: .tcp)
        browser.browseResultsChangedHandler = { (results, changes) in
            for result in results {
                if case .service(let service) = result.endpoint {
                    print(service.name)
                    retval.append([service.name: "IP goes here"])
                }
            }
        }
        browser.start(queue: q)
        sleep(1)  // come on
        return retval
    }

    func connect() {
        connection.start(queue: dispatchQueue)
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
