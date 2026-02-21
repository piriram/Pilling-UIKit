import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class MedicationDetailTestViewController: UIViewController {

    // MARK: - Properties

    private let disposeBag = DisposeBag()
    private let detailAPIService: MedicationDetailAPIServiceProtocol

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "의약품 상세정보 API 테스트"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "품목기준코드(ITEM_SEQ)를 입력하세요"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()

    private let itemSeqTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "예: 200009522"
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        textField.font = .systemFont(ofSize: 16)
        textField.keyboardType = .numberPad
        return textField
    }()

    private let exampleStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()

    private let searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("검색", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()

    private let resultTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 14)
        textView.isEditable = false
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization

    init(detailAPIService: MedicationDetailAPIServiceProtocol) {
        self.detailAPIService = detailAPIService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupExampleButtons()
        bind()

        // 탭하면 키보드 닫기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white
        title = "API 테스트"

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(titleLabel)
        contentView.addSubview(instructionLabel)
        contentView.addSubview(itemSeqTextField)
        contentView.addSubview(exampleStackView)
        contentView.addSubview(searchButton)
        contentView.addSubview(resultTextView)
        view.addSubview(loadingIndicator)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        instructionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        itemSeqTextField.snp.makeConstraints {
            $0.top.equalTo(instructionLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        exampleStackView.snp.makeConstraints {
            $0.top.equalTo(itemSeqTextField.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(120)
        }

        searchButton.snp.makeConstraints {
            $0.top.equalTo(exampleStackView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(50)
        }

        resultTextView.snp.makeConstraints {
            $0.top.equalTo(searchButton.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(400)
            $0.bottom.equalToSuperview().offset(-20)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func setupExampleButtons() {
        let examples = [
            ("머시론정", "200009522"),
            ("야즈정", "200807400"),
            ("센스데이정", "201706350")
        ]

        for (name, itemSeq) in examples {
            let button = UIButton(type: .system)
            button.setTitle("\(name) (\(itemSeq))", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.backgroundColor = .systemGray6
            button.layer.cornerRadius = 8
            button.tag = Int(itemSeq) ?? 0

            button.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.itemSeqTextField.text = itemSeq
                })
                .disposed(by: disposeBag)

            exampleStackView.addArrangedSubview(button)
        }
    }

    private func bind() {
        searchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.searchMedicationDetail()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func searchMedicationDetail() {
        guard let itemSeq = itemSeqTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !itemSeq.isEmpty else {
            showAlert(message: "품목기준코드를 입력하세요")
            return
        }

        view.endEditing(true)
        loadingIndicator.startAnimating()
        resultTextView.text = "검색 중..."

        detailAPIService.fetchMedicationDetail(itemSeq: itemSeq)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] detail in
                    self?.loadingIndicator.stopAnimating()
                    self?.displayResult(detail)
                },
                onError: { [weak self] error in
                    self?.loadingIndicator.stopAnimating()
                    self?.displayError(error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func displayResult(_ detail: MedicationDetailInfo?) {
        guard let detail = detail else {
            resultTextView.text = "❌ 검색 결과가 없습니다."
            return
        }

        let result = """
        ✅ 검색 성공!

        📋 기본 정보
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        제품명: \(detail.itemName)
        제조사: \(detail.entpName)
        품목코드: \(detail.itemSeq)

        💊 복용 주기 (파싱 결과)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        \(detail.dosageInstructions)

        📖 사용법 (원본)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        \(detail.useMethod.isEmpty ? "정보 없음" : detail.useMethod)

        🎯 효능효과
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        \(detail.efficacy.isEmpty ? "정보 없음" : detail.efficacy)

        ⚠️ 주의사항
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        \(detail.precautions.isEmpty ? "정보 없음" : detail.precautions.prefix(200))...

        🩺 부작용
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        \(detail.sideEffects.isEmpty ? "정보 없음" : detail.sideEffects.prefix(200))...

        📦 보관법
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        \(detail.storage.isEmpty ? "정보 없음" : detail.storage)
        """

        resultTextView.text = result
    }

    private func displayError(_ error: Error) {
        let errorMessage: String

        if let apiError = error as? MedicationAPIError {
            switch apiError {
            case .invalidURL:
                errorMessage = "잘못된 URL입니다."
            case .networkError(let err):
                errorMessage = "네트워크 오류: \(err.localizedDescription)"
            case .invalidResponse:
                errorMessage = "잘못된 응답입니다."
            case .httpError(let code):
                errorMessage = "HTTP 오류: \(code)"
            case .apiError(let code, let message):
                errorMessage = "API 오류 [\(code)]: \(message)"
            case .decodingError(let err):
                errorMessage = "데이터 파싱 오류: \(err.localizedDescription)"
            case .cacheCorrupted:
                errorMessage = "캐시 데이터가 손상되었습니다."
            case .regionNotSupported:
                errorMessage = "지원하지 않는 지역입니다."
            }
        } else {
            errorMessage = error.localizedDescription
        }

        resultTextView.text = """
        ❌ 오류 발생

        \(errorMessage)

        다시 시도해주세요.
        """

        showAlert(message: errorMessage)
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
