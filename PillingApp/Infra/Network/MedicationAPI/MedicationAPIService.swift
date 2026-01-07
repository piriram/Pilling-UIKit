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

                    print("🔍 [검색 API] 키워드: \"\(keyword)\"")
                    print("   전체 응답: \(apiResponse.body.items.count)개")

                    // 전체 항목 출력
                    for (index, item) in apiResponse.body.items.prefix(10).enumerated() {
                        print("   [\(index + 1)] \(item.itemName ?? "이름없음") | 제조사: \(item.entpName ?? "없음") | 타입: \(item.productType ?? "없음") | 취소: \(item.cancelDate ?? "없음") | 허가: \(item.itemPermitDate ?? "없음")")
                    }

                    // 유효기간 만료/취소된 약품 필터링
                    let validItems = apiResponse.body.items.filter { $0.isValid }
                    print("   ✅ 유효한 약품: \(validItems.count)개")

                    let medications = validItems.map { $0.toDomainModel() }

                    // 피임약만 필터링해서 출력
                    let contraceptives = medications.filter { $0.isContraceptivePill }
                    print("   💊 피임약: \(contraceptives.count)개")
                    for med in contraceptives {
                        print("      - \(med.name) (\(med.manufacturer))")
                    }

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
