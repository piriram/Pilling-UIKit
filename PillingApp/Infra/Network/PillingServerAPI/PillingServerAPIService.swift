import Foundation
import RxSwift

enum PillingServerError: Error {
    case invalidURL
    case unauthorized
    case notFound
    case conflict
    case unprocessableEntity
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
}

protocol PillingServerAPIServiceProtocol {
    func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        responseType: Response.Type
    ) -> Observable<Response>

    func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        responseType: Response.Type
    ) -> Observable<Response>

    func get<Response: Decodable>(
        path: String,
        responseType: Response.Type
    ) -> Observable<Response>

    func delete<Response: Decodable>(
        path: String,
        responseType: Response.Type
    ) -> Observable<Response>
}

final class PillingServerAPIService: PillingServerAPIServiceProtocol {

    private let baseURL = "https://pilling.duckdns.org"
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func post<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body?,
        responseType: Response.Type
    ) -> Observable<Response> {
        request(method: "POST", path: path, body: body, responseType: responseType)
    }

    func patch<Body: Encodable, Response: Decodable>(
        path: String,
        body: Body,
        responseType: Response.Type
    ) -> Observable<Response> {
        request(method: "PATCH", path: path, body: body, responseType: responseType)
    }

    func get<Response: Decodable>(
        path: String,
        responseType: Response.Type
    ) -> Observable<Response> {
        request(method: "GET", path: path, body: Optional<EmptyBody>.none, responseType: responseType)
    }

    func delete<Response: Decodable>(
        path: String,
        responseType: Response.Type
    ) -> Observable<Response> {
        request(method: "DELETE", path: path, body: Optional<EmptyBody>.none, responseType: responseType)
    }

    // MARK: - Private

    private struct EmptyBody: Encodable {}

    private func request<Body: Encodable, Response: Decodable>(
        method: String,
        path: String,
        body: Body?,
        responseType: Response.Type
    ) -> Observable<Response> {
        Observable.create { [weak self] observer in
            guard let self else {
                observer.onError(PillingServerError.invalidURL)
                return Disposables.create()
            }

            guard let url = URL(string: self.baseURL + path) else {
                observer.onError(PillingServerError.invalidURL)
                return Disposables.create()
            }

            var request = URLRequest(url: url)
            request.httpMethod = method
            request.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if let body {
                do {
                    request.httpBody = try JSONEncoder().encode(body)
                } catch {
                    observer.onError(PillingServerError.networkError(error))
                    return Disposables.create()
                }
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error {
                    observer.onError(PillingServerError.networkError(error))
                    return
                }

                guard let http = response as? HTTPURLResponse else {
                    observer.onError(PillingServerError.invalidResponse)
                    return
                }

                switch http.statusCode {
                case 200, 201:
                    guard let data else {
                        observer.onError(PillingServerError.invalidResponse)
                        return
                    }
                    do {
                        let decoded = try JSONDecoder().decode(Response.self, from: data)
                        observer.onNext(decoded)
                        observer.onCompleted()
                    } catch {
                        observer.onError(PillingServerError.decodingError(error))
                    }
                case 401:
                    observer.onError(PillingServerError.unauthorized)
                case 404:
                    observer.onError(PillingServerError.notFound)
                case 409:
                    observer.onError(PillingServerError.conflict)
                case 422:
                    observer.onError(PillingServerError.unprocessableEntity)
                default:
                    observer.onError(PillingServerError.httpError(http.statusCode))
                }
            }

            task.resume()
            return Disposables.create { task.cancel() }
        }
    }
}
