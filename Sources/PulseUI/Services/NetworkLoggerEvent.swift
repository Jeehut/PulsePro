// Copyright (c) 2020 Alexander Grebenyuk (github.com/kean).
// Licensed under Apache License v2.0 with Runtime Library Exception.

import Foundation
import Pulse
import Logging

public enum NetworkLoggerMetadataKey: String {
    case taskId = "networkEventTaskId"
    case eventType = "networkEventType"
    case taskType = "networkEventTaskType"
    case payload = "networkEventPayload"
}

extension NetworkLoggerMetadataKey {
    static let createdAt = "networkEventCreatedAt"
}

public enum NetworkLoggerEventType: String, Codable {
    case taskDidStart
    case taskDidComplete

    case dataTaskDidReceieveResponse
    case dataTaskDidReceiveData
}

public enum NetworkLoggerEvent {
    case taskDidStart(TaskDidStart)
    case taskDidComplete(TaskDidComplete)
    case dataTaskDidReceieveResponse(DataTaskDidReceieveResponse)
    case dataTaskDidReceiveData(DataTaskDidReceiveData)

    public struct TaskDidStart: Codable {
        public let request: NetworkLoggerRequest
    }

    public struct TaskDidComplete: Codable {
        public let request: NetworkLoggerRequest
        public let response: NetworkLoggerResponse?
        public let error: NetworkLoggerError?
        public let requestBodyKey: String?
        public let responseBodyKey: String?
        public let metrics: NetworkLoggerMetrics?
    }

    public struct DataTaskDidReceieveResponse: Codable {
        public let response: NetworkLoggerResponse
    }

    public struct DataTaskDidReceiveData: Codable {
        public let dataCount: Int
    }
}

public struct NetworkLoggerRequest: Codable {
    public let url: URL?
    public let httpMethod: String?
    public let headers: [String: String]
    /// `URLRequest.CachePolicy` raw value
    public let cachePolicy: UInt
    public let timeoutInterval: TimeInterval
    public let allowsCellularAccess: Bool
    public let allowsExpensiveNetworkAccess: Bool
    public let allowsConstrainedNetworkAccess: Bool
    public let httpShouldHandleCookies: Bool
    public let httpShouldUsePipelining: Bool

    init(urlRequest: URLRequest) {
        self.url = urlRequest.url
        self.httpMethod = urlRequest.httpMethod
        self.headers = urlRequest.allHTTPHeaderFields ?? [:]
        self.cachePolicy = urlRequest.cachePolicy.rawValue
        self.timeoutInterval = urlRequest.timeoutInterval
        self.allowsCellularAccess = urlRequest.allowsCellularAccess
        self.allowsExpensiveNetworkAccess = urlRequest.allowsExpensiveNetworkAccess
        self.allowsConstrainedNetworkAccess = urlRequest.allowsConstrainedNetworkAccess
        self.httpShouldHandleCookies = urlRequest.httpShouldHandleCookies
        self.httpShouldUsePipelining = urlRequest.httpShouldUsePipelining
    }
}

public struct NetworkLoggerResponse: Codable {
    public let statusCode: Int?
    public let headers: [String: String]

    init(urlResponse: URLResponse) {
        let httpResponse = urlResponse as? HTTPURLResponse
        self.statusCode = httpResponse?.statusCode
        self.headers = httpResponse?.allHeaderFields as? [String: String] ?? [:]
    }
}

public struct NetworkLoggerError: Codable {
    public let code: Int
    public let domain: String
    public let localizedDescription: String

    init(error: Error) {
        let error = error as NSError
        self.code = error.code
        self.domain = error.domain
        self.localizedDescription = error.localizedDescription
    }
}

public struct NetworkLoggerMetrics: Codable {
    public let taskInterval: DateInterval
    public let redirectCount: Int
    public let transactions: [NetworkLoggerTransactionMetrics]

    init(metrics: URLSessionTaskMetrics) {
        self.taskInterval = metrics.taskInterval
        self.redirectCount = metrics.redirectCount
        self.transactions = metrics.transactionMetrics.map(NetworkLoggerTransactionMetrics.init)
    }
}

public final class NetworkLoggerTransactionMetrics: Codable {
    public let request: NetworkLoggerRequest?
    public let response: NetworkLoggerResponse?
    public let fetchStartDate: Date?
    public let domainLookupStartDate: Date?
    public let domainLookupEndDate: Date?
    public let connectStartDate: Date?
    public let secureConnectionStartDate: Date?
    public let secureConnectionEndDate: Date?
    public let connectEndDate: Date?
    public let requestStartDate: Date?
    public let requestEndDate: Date?
    public let responseStartDate: Date?
    public let responseEndDate: Date?
    public let networkProtocolName: String?
    public let isProxyConnection: Bool
    public let isReusedConnection: Bool
    /// `URLSessionTaskMetrics.ResourceFetchType` enum raw value
    public let resourceFetchType: Int
    public let countOfRequestHeaderBytesSent: Int64
    public let countOfRequestBodyBytesSent: Int64
    public let countOfRequestBodyBytesBeforeEncoding: Int64
    public let countOfResponseHeaderBytesReceived: Int64
    public let countOfResponseBodyBytesReceived: Int64
    public let countOfResponseBodyBytesAfterDecoding: Int64
    public let localAddress: String?
    public let remoteAddress: String?
    public let isCellular: Bool
    public let isExpensive: Bool
    public let isConstrained: Bool
    public let isMultipath: Bool
    public let localPort: Int?
    public let remotePort: Int?
    /// `tls_protocol_version_t` enum raw value
    public let negotiatedTLSProtocolVersion: UInt16?
    /// `tls_ciphersuite_t`  enum raw value
    public let negotiatedTLSCipherSuite: UInt16?

    init(metrics: URLSessionTaskTransactionMetrics) {
        self.request = NetworkLoggerRequest(urlRequest: metrics.request)
        self.response = metrics.response.map(NetworkLoggerResponse.init)
        self.fetchStartDate = metrics.fetchStartDate
        self.domainLookupStartDate = metrics.domainLookupStartDate
        self.domainLookupEndDate = metrics.domainLookupEndDate
        self.connectStartDate = metrics.connectStartDate
        self.secureConnectionStartDate = metrics.secureConnectionStartDate
        self.secureConnectionEndDate = metrics.secureConnectionEndDate
        self.connectEndDate = metrics.connectEndDate
        self.requestStartDate = metrics.requestStartDate
        self.requestEndDate = metrics.requestEndDate
        self.responseStartDate = metrics.responseStartDate
        self.responseEndDate = metrics.responseEndDate
        self.networkProtocolName = metrics.networkProtocolName
        self.isProxyConnection = metrics.isProxyConnection
        self.isReusedConnection = metrics.isReusedConnection
        self.resourceFetchType = metrics.resourceFetchType.rawValue
        self.countOfRequestHeaderBytesSent = metrics.countOfRequestHeaderBytesSent
        self.countOfRequestBodyBytesSent = metrics.countOfRequestBodyBytesSent
        self.countOfRequestBodyBytesBeforeEncoding = metrics.countOfRequestBodyBytesBeforeEncoding
        self.countOfResponseHeaderBytesReceived = metrics.countOfResponseHeaderBytesReceived
        self.countOfResponseBodyBytesReceived = metrics.countOfResponseBodyBytesReceived
        self.countOfResponseBodyBytesAfterDecoding = metrics.countOfResponseBodyBytesAfterDecoding
        self.localAddress = metrics.localAddress
        self.remoteAddress = metrics.remoteAddress
        self.isCellular = metrics.isCellular
        self.isExpensive = metrics.isExpensive
        self.isConstrained = metrics.isConstrained
        self.isMultipath = metrics.isMultipath
        self.localPort = metrics.localPort
        self.remotePort = metrics.remotePort
        self.negotiatedTLSProtocolVersion = metrics.negotiatedTLSProtocolVersion?.rawValue
        self.negotiatedTLSCipherSuite = metrics.negotiatedTLSCipherSuite?.rawValue
    }
}

public enum NetworkLoggerTaskType: String, Codable {
    case dataTask
    case downloadTask
    case uploadTask
    case streamTask
    case webSocketTask

    init(task: URLSessionTask) {
        switch task {
        case task as URLSessionDataTask: self = .dataTask
        case task as URLSessionDownloadTask: self = .downloadTask
        case task as URLSessionWebSocketTask: self = .webSocketTask
        case task as URLSessionStreamTask: self = .streamTask
        case task as URLSessionUploadTask: self = .uploadTask
        default:
            assertionFailure("Unknown task type: \(task)")
            self = .dataTask
        }
    }
}
