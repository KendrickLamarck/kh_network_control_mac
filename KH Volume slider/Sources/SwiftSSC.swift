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
    let transaction = SSCTransaction()

    enum SSCDeviceError: Error {
        case ipError
        case portError
        case sendError
        case receiveError
    }

    init(ip ip_: String, port port_: Int = 45) throws {
        ip = ip_
        port = port_
        guard let addr = IPv6Address(ip) else {
            throw SSCDeviceError.ipError
        }
        let hostEndpoint = NWEndpoint.Host.ipv6(addr)
        guard let portEndpoint = NWEndpoint.Port(String(port)) else {
            throw SSCDeviceError.portError
        }
        connection = NWConnection(host: hostEndpoint, port: portEndpoint, using: .tcp)
        dispatchQueue = DispatchQueue(label: "KH")
    }

    func connect() {
        connection.start(queue: dispatchQueue)
    }

    func disconnect() {
        connection.cancel()
    }

    func sendMessage(_ TXString: String) {
        let sendCompHandler = NWConnection.SendCompletion.contentProcessed {
            error in
            if let error = error {
                transaction.error = String(describing: error)
                return
            }
            transaction.TX = TXString
        }
        let TX = TXString.appending("\r\n").data(using: .ascii)!
        connection.send(content: TX, completion: sendCompHandler)
    }

    func receiveMessage(maximumLength: Int = 512) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: maximumLength) {
            (content, context, isComplete, error) in
            guard let content = content else {
                transaction.error = String(describing: error)
                return
            }
            transaction.RX = String(data: content, encoding: .utf8) ?? "No Response"
        }
    }
}
