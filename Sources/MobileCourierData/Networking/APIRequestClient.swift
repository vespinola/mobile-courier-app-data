//
//  APIRequestClient.swift
//  mobile-courier-app
//
//  Created by Vladimir Espinola on 2024-05-06.
//

import Foundation
import os

enum APIErrorMessage: Error {
  case invalidRequest
  case invalidResponse
  case timeout
  case requestFailed(statusCode: Int)
  case decodeFailed
}

protocol APIRequestClientProtocol {
  func performRequest<T: Decodable>(endpoint: Endpoint, decoder: JSONDecoder) async throws -> T
}

final class APIRequestClient: NSObject, APIRequestClientProtocol {

  private lazy var logger: Logger = .init()

  private lazy var delegate: URLSessionDelegate? = CustomSessionDelegate()

  func performRequest<T: Decodable>(endpoint: Endpoint, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
    #if DEBUG
    
    if let mockfile = endpoint.mockFile, let fileUrl = Bundle.module.url(forResource: mockfile, withExtension: "json") {
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let data = try Data(contentsOf: fileUrl, options: .uncached)
      let decodedData = try decoder.decode(T.self, from: data)
      try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)

      logger.debug("\(mockfile): \(data.prettyPrintedJSONString ?? "")")

      return decodedData
    }
    #endif

    guard let urlRequest = try? endpoint.asRequest() else {
      throw APIErrorMessage.invalidRequest
    }

    do {
      let configuration = URLSessionConfiguration.default
      configuration.timeoutIntervalForRequest = 10
      configuration.timeoutIntervalForResource = 10
      configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
      configuration.urlCache = nil

      let (data, response) = try await URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        .data(for: urlRequest)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw APIErrorMessage.invalidResponse
      }

      guard (200...299).contains(httpResponse.statusCode) else {
        throw APIErrorMessage.requestFailed(statusCode: httpResponse.statusCode)
      }

      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let decodedData = try decoder.decode(T.self, from: data)

      logger.debug("\(response.url?.absoluteString ?? ""): \(data.prettyPrintedJSONString ?? "")")

      return decodedData
    } catch {
      if (error as NSError).code == NSURLErrorTimedOut {
        throw APIErrorMessage.timeout
      }

      throw error
    }
  }
}
