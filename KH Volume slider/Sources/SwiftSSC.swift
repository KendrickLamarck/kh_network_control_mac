//
//  SwiftSSC.swift
//  KH Volume slider
//
//  Created by Leander Blume on 25.03.25.
//
import Foundation
import Network

struct SSCDevice {
    let ip: String
    let port: Int
    private let connection: NWConnection
    private let dispatchQueue: DispatchQueue
    
    enum SSCDeviceError: Error {
        case ipError
        case portError
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
    
    func sendMessage(_ TXString: String) {
        let sendCompHandler = NWConnection.SendCompletion.contentProcessed {
            error in
            if error != nil {
                print("Error sending: \(String(describing: error))")
            }
        }
        let TX = TXString.appending("\r\n").data(using: .ascii)!
        connection.send(content: TX, completion: sendCompHandler)
    }
    
    func receiveMessage() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 512) {
            (content, context, isComplete, error) in
            print("Response:")
            if content == nil {
                print("No response")
                return
            }
            print(String(data: content!, encoding: .utf8) ?? "NONE")
        }
        // there must be a better way
        sleep(1)
        connection.cancel()
    }
}
