import Foundation
import RxSwift

protocol MedicationDetailAPIServiceProtocol {
    func fetchMedicationDetail(itemSeq: String) -> Observable<MedicationDetailInfo?>
}

final class MedicationDetailAPIService: MedicationDetailAPIServiceProtocol {

    private let baseURL = "https://apis.data.go.kr/1471000/DrbEasyDrugInfoService/getDrbEasyDrugList"
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func fetchMedicationDetail(itemSeq: String) -> Observable<MedicationDetailInfo?> {
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

            var components = URLComponents(string: self.baseURL)
            components?.percentEncodedQueryItems = [
                URLQueryItem(name: "serviceKey", value: serviceKey),
                URLQueryItem(name: "itemSeq", value: itemSeq),
                URLQueryItem(name: "type", value: "json"),
            ]

            guard let url = components?.url else {
                observer.onError(MedicationAPIError.invalidURL)
                return Disposables.create()
            }

            print("🔍 [Detail API] Request URL: \(url.absoluteString)")

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

                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔍 [Detail API] Response: \(responseString.prefix(500))...")
                }

                do {
                    let apiResponse = try JSONDecoder().decode(MedicationDetailAPIResponse.self, from: data)

                    if apiResponse.header.resultCode != "00" {
                        observer.onError(MedicationAPIError.apiError(
                            code: apiResponse.header.resultCode,
                            message: apiResponse.header.resultMsg
                        ))
                        return
                    }

                    let detailInfo = apiResponse.body.items.first?.toDomainModel()
                    print("✅ [Detail API] Success: \(detailInfo?.itemName ?? "없음")")
                    observer.onNext(detailInfo)
                    observer.onCompleted()

                } catch {
                    print("❌ [Detail API] Decoding error: \(error)")
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
