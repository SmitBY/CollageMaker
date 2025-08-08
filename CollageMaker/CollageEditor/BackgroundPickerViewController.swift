import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol BackgroundPickerDelegate: AnyObject {
    func backgroundPicker(_ picker: BackgroundPickerViewController, didSelectColor color: UIColor)
    func backgroundPicker(_ picker: BackgroundPickerViewController, didSelectImage image: UIImage)
    func backgroundPickerDidRequestGallery(_ picker: BackgroundPickerViewController)
}

class BackgroundPickerViewController: UIViewController {
    
    weak var delegate: BackgroundPickerDelegate?
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    // Секция выбора цвета
    private let colorSectionLabel = UILabel()
    private let colorCollectionView: UICollectionView
    private let customColorButton = UIButton(type: .system)
    
    // Секция готовых фонов
    private let backgroundSectionLabel = UILabel()
    private let backgroundCollectionView: UICollectionView
    
    // Кнопка выбора из галереи
    private let galleryButton = UIButton(type: .system)
    
    // Данные
    private let predefinedColors: [UIColor] = [
        .white, .black, .systemGray, .systemGray2, .systemGray3,
        .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemBlue,
        .systemIndigo, .systemPurple, .systemPink, .systemTeal, .systemCyan
    ]
    
    private var backgroundImages: [UIImage] = []
    
    // MARK: - Initialization
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        // Настройка collection view для цветов
        let colorLayout = UICollectionViewFlowLayout()
        colorLayout.scrollDirection = .horizontal
        colorLayout.minimumInteritemSpacing = 10
        colorLayout.minimumLineSpacing = 10
        colorCollectionView = UICollectionView(frame: .zero, collectionViewLayout: colorLayout)
        
        // Настройка collection view для фонов
        let backgroundLayout = UICollectionViewFlowLayout()
        backgroundLayout.scrollDirection = .horizontal
        backgroundLayout.minimumInteritemSpacing = 10
        backgroundLayout.minimumLineSpacing = 10
        backgroundCollectionView = UICollectionView(frame: .zero, collectionViewLayout: backgroundLayout)
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        loadBackgroundImages()
    }

    // Белый статус-бар для модального затемнения
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Настройка контейнера
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 8
        
        // Настройка заголовка
        titleLabel.text = "Выбор фона"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        
        // Настройка кнопки закрытия
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .systemGray
        
        // Настройка секции цветов
        colorSectionLabel.text = "Цвет фона"
        colorSectionLabel.textColor = .white
        colorSectionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        colorCollectionView.backgroundColor = .clear
        colorCollectionView.showsHorizontalScrollIndicator = false
        colorCollectionView.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell")
        colorCollectionView.delegate = self
        
        customColorButton.setTitle("Свой цвет", for: .normal)
        customColorButton.backgroundColor = .systemBlue
        customColorButton.setTitleColor(.white, for: .normal)
        customColorButton.layer.cornerRadius = 8
        
        // Настройка секции фонов
        backgroundSectionLabel.text = "Готовые фоны"
        backgroundSectionLabel.textColor = .white
        backgroundSectionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        
        backgroundCollectionView.backgroundColor = .clear
        backgroundCollectionView.showsHorizontalScrollIndicator = false
        backgroundCollectionView.register(BackgroundImageCell.self, forCellWithReuseIdentifier: "BackgroundImageCell")
        backgroundCollectionView.delegate = self
        
        // Настройка кнопки галереи
        galleryButton.setTitle("Выбрать из галереи", for: .normal)
        galleryButton.backgroundColor = .systemGreen
        galleryButton.setTitleColor(.white, for: .normal)
        galleryButton.layer.cornerRadius = 8
        
        // Добавление элементов
        view.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(colorSectionLabel)
        containerView.addSubview(colorCollectionView)
        containerView.addSubview(customColorButton)
        containerView.addSubview(backgroundSectionLabel)
        containerView.addSubview(backgroundCollectionView)
        containerView.addSubview(galleryButton)
        
        // Constraints
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(500)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.width.height.equalTo(30)
        }
        
        colorSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20)
        }
        
        colorCollectionView.snp.makeConstraints { make in
            make.top.equalTo(colorSectionLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
        
        customColorButton.snp.makeConstraints { make in
            make.top.equalTo(colorCollectionView.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(100)
            make.height.equalTo(40)
        }
        
        backgroundSectionLabel.snp.makeConstraints { make in
            make.top.equalTo(customColorButton.snp.bottom).offset(30)
            make.leading.equalToSuperview().offset(20)
        }
        
        backgroundCollectionView.snp.makeConstraints { make in
            make.top.equalTo(backgroundSectionLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }
        
        galleryButton.snp.makeConstraints { make in
            make.top.equalTo(backgroundCollectionView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func setupBindings() {
        // Закрытие
        closeButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // Выбор своего цвета
        customColorButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showColorPicker()
            })
            .disposed(by: disposeBag)
        
        // Выбор из галереи
        galleryButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.delegate?.backgroundPickerDidRequestGallery(self)
            })
            .disposed(by: disposeBag)
        
        // Настройка collection view для цветов
        Observable.just(predefinedColors)
            .bind(to: colorCollectionView.rx.items(cellIdentifier: "ColorCell", cellType: ColorCell.self)) { index, color, cell in
                cell.configure(with: color)
            }
            .disposed(by: disposeBag)
        
        colorCollectionView.rx.modelSelected(UIColor.self)
            .subscribe(onNext: { [weak self] color in
                guard let self = self else { return }
                self.delegate?.backgroundPicker(self, didSelectColor: color)
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        // Настройка collection view для фонов - привязка будет после загрузки
        backgroundCollectionView.rx.modelSelected(UIImage.self)
            .subscribe(onNext: { [weak self] image in
                guard let self = self else { return }
                self.delegate?.backgroundPicker(self, didSelectImage: image)
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func loadBackgroundImages() {
        var allImages: [UIImage] = []
        
        // Загружаем встроенные фоны из bundle
        let bundleImages = loadBundleBackgrounds()
        allImages.append(contentsOf: bundleImages)
        print("Загружено \(bundleImages.count) фонов из bundle")
        
        // Загружаем пользовательские фоны из Documents
        let userImages = loadUserBackgrounds()
        allImages.append(contentsOf: userImages)
        print("Загружено \(userImages.count) пользовательских фонов")
        
        backgroundImages = allImages
        print("Всего загружено фонов: \(allImages.count)")
        
        // Обновляем collection view
        DispatchQueue.main.async {
            // Привязываем данные к collection view
            Observable.just(self.backgroundImages)
                .bind(to: self.backgroundCollectionView.rx.items(cellIdentifier: "BackgroundImageCell", cellType: BackgroundImageCell.self)) { index, image, cell in
                    cell.configure(with: image)
                }
                .disposed(by: self.disposeBag)
        }
    }
    
    private func loadBundleBackgrounds() -> [UIImage] {
        var images: [UIImage] = []
        
        // Способ 1: Поиск папки Backgrounds в bundle через Bundle.main.path
        if let bundlePath = Bundle.main.path(forResource: "Backgrounds", ofType: nil) {
            do {
                let bundleContents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let bundleImages = bundleContents.compactMap { filename -> UIImage? in
                    let pathExtension = (filename as NSString).pathExtension.lowercased()
                    guard ["png", "jpg", "jpeg"].contains(pathExtension) else { return nil }
                    let fullPath = bundlePath + "/" + filename
                    print("Загружаем фон: \(filename) из \(fullPath)")
                    return UIImage(contentsOfFile: fullPath)
                }
                images.append(contentsOf: bundleImages)
                print("✅ Способ 1: Загружено \(bundleImages.count) фонов из \(bundlePath)")
            } catch {
                print("❌ Способ 1: Ошибка загрузки фонов из bundle: \(error)")
            }
        } else {
            print("❌ Способ 1: Папка Backgrounds не найдена через Bundle.main.path")
        }
        
        // Способ 2: Поиск через resourcePath + /Backgrounds
        if images.isEmpty, let resourcePath = Bundle.main.resourcePath {
            let backgroundsPath = resourcePath + "/Backgrounds"
            print("Проверяем путь: \(backgroundsPath)")
            
            if FileManager.default.fileExists(atPath: backgroundsPath) {
                do {
                    let bundleContents = try FileManager.default.contentsOfDirectory(atPath: backgroundsPath)
                    print("Найдены файлы в Backgrounds: \(bundleContents)")
                    
                    let bundleImages = bundleContents.compactMap { filename -> UIImage? in
                        let pathExtension = (filename as NSString).pathExtension.lowercased()
                        guard ["png", "jpg", "jpeg"].contains(pathExtension) else { 
                            print("Пропускаем файл (неподходящее расширение): \(filename)")
                            return nil 
                        }
                        let fullPath = backgroundsPath + "/" + filename
                        print("Загружаем фон: \(filename) из \(fullPath)")
                        
                        if let image = UIImage(contentsOfFile: fullPath) {
                            print("✅ Успешно загружен: \(filename)")
                            return image
                        } else {
                            print("❌ Не удалось загрузить: \(filename)")
                            return nil
                        }
                    }
                    images.append(contentsOf: bundleImages)
                    print("✅ Способ 2: Загружено \(bundleImages.count) фонов из \(backgroundsPath)")
                } catch {
                    print("❌ Способ 2: Ошибка загрузки фонов: \(error)")
                }
            } else {
                print("❌ Способ 2: Папка \(backgroundsPath) не существует")
            }
        }
        
        // Способ 3: Поиск всех файлов в корне bundle (если папка Backgrounds не найдена)
        if images.isEmpty, let resourcePath = Bundle.main.resourcePath {
            print("Ищем фоны в корне bundle: \(resourcePath)")
            do {
                let allFiles = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("Все файлы в bundle: \(allFiles.filter { $0.contains("jpg") || $0.contains("png") })")
                
                let imageFiles = allFiles.filter { filename in
                    let pathExtension = (filename as NSString).pathExtension.lowercased()
                    let isImage = ["png", "jpg", "jpeg"].contains(pathExtension)
                    let isNotSticker = !filename.hasPrefix("sticker") && !filename.contains("image-")
                    return isImage && isNotSticker
                }
                
                print("Подходящие файлы для фонов: \(imageFiles)")
                
                for filename in imageFiles {
                    let fullPath = resourcePath + "/" + filename
                    if let image = UIImage(contentsOfFile: fullPath) {
                        images.append(image)
                        print("✅ Способ 3: Загружен фон \(filename) из корня bundle")
                    } else {
                        print("❌ Способ 3: Не удалось загрузить \(filename)")
                    }
                }
            } catch {
                print("❌ Способ 3: Ошибка чтения корня bundle: \(error)")
            }
        }
        
        // Способ 4: Прямая загрузка всех файлов из папки Backgrounds
        // Поскольку папка не добавлена в bundle, загружаем файлы напрямую из файловой системы
        let backgroundsDirectoryPath = Bundle.main.bundlePath + "/Backgrounds"
        print("Проверяем прямой путь к папке: \(backgroundsDirectoryPath)")
        
        if FileManager.default.fileExists(atPath: backgroundsDirectoryPath) {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: backgroundsDirectoryPath)
                print("Найдены файлы в папке Backgrounds: \(files)")
                
                for filename in files {
                    let pathExtension = (filename as NSString).pathExtension.lowercased()
                    guard ["png", "jpg", "jpeg"].contains(pathExtension) else { continue }
                    
                    let fullPath = backgroundsDirectoryPath + "/" + filename
                    if let image = UIImage(contentsOfFile: fullPath) {
                        images.append(image)
                        print("✅ Способ 4: Загружен фон \(filename)")
                    } else {
                        print("❌ Способ 4: Не удалось загрузить \(filename)")
                    }
                }
            } catch {
                print("❌ Способ 4: Ошибка чтения папки Backgrounds: \(error)")
            }
        } else {
            print("❌ Способ 4: Папка Backgrounds не найдена по пути \(backgroundsDirectoryPath)")
        }
        
        // Способ 5: Загрузка известных файлов через UIImage(named:) как fallback
        if images.isEmpty {
            let knownBackgrounds = [
                "3d29796ba89570efd56d108a5c3ad58c",
                "image",
                "new-year-6615832_1280",
                "fuzzy-hearts-9659075_1280"
            ]
            
            for filename in knownBackgrounds {
                if let image = UIImage(named: filename) {
                    images.append(image)
                    print("✅ Способ 5: Загружен фон \(filename) через UIImage(named:)")
                } else {
                    print("❌ Способ 5: Не удалось загрузить фон \(filename)")
                }
            }
        }
        
        print("🎯 Итого загружено фонов: \(images.count)")
        return images
    }
    
    private func loadUserBackgrounds() -> [UIImage] {
        // Создаем папку в Documents если её нет (для пользовательских фонов)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let userBackgroundsPath = documentsPath?.appendingPathComponent("CollageMaker/Backgrounds")
        
        guard let userPath = userBackgroundsPath else { return [] }
        
        try? FileManager.default.createDirectory(at: userPath, withIntermediateDirectories: true)
        
        // Загружаем изображения из Documents (пользовательские фоны)
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: userPath, includingPropertiesForKeys: nil)
            let imageURLs = fileURLs.filter { url in
                let pathExtension = url.pathExtension.lowercased()
                return ["png", "jpg", "jpeg"].contains(pathExtension)
            }
            
            let userImages = imageURLs.compactMap { url -> UIImage? in
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else { return nil }
                return image
            }
            return userImages
        } catch {
            print("Ошибка загрузки пользовательских фонов: \(error)")
            return []
        }
    }
    
    private func showColorPicker() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.delegate = self
        colorPicker.supportsAlpha = false
        present(colorPicker, animated: true)
    }
}

// MARK: - UIColorPickerViewControllerDelegate

extension BackgroundPickerViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor
        delegate?.backgroundPicker(self, didSelectColor: selectedColor)
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension BackgroundPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == colorCollectionView {
            return CGSize(width: 40, height: 40)
        } else if collectionView == backgroundCollectionView {
            return CGSize(width: 80, height: 80)
        }
        return CGSize(width: 50, height: 50)
    }
}

// MARK: - Color Cell

class ColorCell: UICollectionViewCell {
    private let colorView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        colorView.layer.cornerRadius = 20
        colorView.layer.borderWidth = 2
        colorView.layer.borderColor = UIColor.systemGray4.cgColor
        
        contentView.addSubview(colorView)
        colorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(with color: UIColor) {
        colorView.backgroundColor = color
        
        // Для белого цвета делаем более заметную границу
        if color == .white {
            colorView.layer.borderColor = UIColor.systemGray2.cgColor
            colorView.layer.borderWidth = 3
        } else {
            colorView.layer.borderColor = UIColor.systemGray4.cgColor
            colorView.layer.borderWidth = 2
        }
    }
}

// MARK: - Background Image Cell

class BackgroundImageCell: UICollectionViewCell {
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
} 