import Foundation
import RxSwift

protocol MedicationAPIServiceProtocol {
    func fetchMedications(keyword: String) -> Observable<[MedicationInfo]>
}

final class MedicationAPIService: MedicationAPIServiceProtocol {

    private let baseURL = "https://apis.data.go.kr/1471000/DrugPrdtPrmsnInfoService07/getDrugPrdtPrmsnInq07"
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchMedications(keyword: String) -> Observable<[MedicationInfo]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(MedicationAPIError.invalidURL)
                return Disposables.create()
            }

            let normalizedApiKey = (self.apiKey.removingPercentEncoding ?? self.apiKey)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalizedApiKey.isEmpty else {
                observer.onError(MedicationAPIError.apiError(code: "NO_API_KEY", message: "서비스 키가 비어있습니다"))
                return Disposables.create()
            }

            let serviceKey: String
            if self.apiKey.contains("%") {
                serviceKey = self.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                var allowed = CharacterSet.urlQueryAllowed
                allowed.remove(charactersIn: "+=")
                serviceKey = normalizedApiKey.addingPercentEncoding(withAllowedCharacters: allowed) ?? normalizedApiKey
            }

            let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keyword
            var components = URLComponents(string: self.baseURL)
            components?.percentEncodedQueryItems = [
                URLQueryItem(name: "serviceKey", value: serviceKey),
                URLQueryItem(name: "item_name", value: encodedKeyword),
                URLQueryItem(name: "type", value: "json"),
                URLQueryItem(name: "pageNo", value: "1"),
                URLQueryItem(name: "numOfRows", value: "100"),
            ]

            guard let url = components?.url else {
                observer.onError(MedicationAPIError.invalidURL)
                return Disposables.create()
            }

            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    observer.onError(MedicationAPIError.networkError(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.onError(MedicationAPIError.invalidResponse)
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    observer.onError(MedicationAPIError.httpError(statusCode: httpResponse.statusCode))
                    return
                }

                guard let data = data else {
                    observer.onError(MedicationAPIError.invalidResponse)
                    return
                }

                do {
                    let apiResponse = try JSONDecoder().decode(MedicationAPIResponse.self, from: data)

                    if apiResponse.header.resultCode != "00" {
                        observer.onError(MedicationAPIError.apiError(
                            code: apiResponse.header.resultCode,
                            message: apiResponse.header.resultMsg
                        ))
                        return
                    }

                    // 유효기간 만료/취소된 약품 필터링
                    let validItems = apiResponse.body.items.filter { $0.isValid }
                    let medications = validItems.map { $0.toDomainModel() }

                    observer.onNext(medications)
                    observer.onCompleted()

                } catch {
                    observer.onError(MedicationAPIError.decodingError(error))
                }
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
