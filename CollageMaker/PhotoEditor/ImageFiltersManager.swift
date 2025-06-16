import UIKit
import CoreImage

class ImageFiltersManager {
    
    enum FilterType: String, CaseIterable {
        case none = "Оригинал"
        case sepia = "Сепия"
        case noir = "Черно-белый"
        case vintage = "Винтаж"
        case vivid = "Яркий"
        case dramatic = "Драматичный"
        case mono = "Монохром"
        case tonal = "Тональный"
        case fade = "Выцветший"
        case process = "Процесс"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    private let context = CIContext()
    
    func applyFilter(_ filterType: FilterType, to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filteredImage: CIImage
        
        switch filterType {
        case .none:
            return image
            
        case .sepia:
            filteredImage = applySepia(to: ciImage)
            
        case .noir:
            filteredImage = applyNoir(to: ciImage)
            
        case .vintage:
            filteredImage = applyVintage(to: ciImage)
            
        case .vivid:
            filteredImage = applyVivid(to: ciImage)
            
        case .dramatic:
            filteredImage = applyDramatic(to: ciImage)
            
        case .mono:
            filteredImage = applyMono(to: ciImage)
            
        case .tonal:
            filteredImage = applyTonal(to: ciImage)
            
        case .fade:
            filteredImage = applyFade(to: ciImage)
            
        case .process:
            filteredImage = applyProcess(to: ciImage)
        }
        
        guard let cgImage = context.createCGImage(filteredImage, from: filteredImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    // MARK: - Filter Implementations
    
    private func applySepia(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CISepiaTone") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: kCIInputIntensityKey)
        return filter.outputImage ?? image
    }
    
    private func applyNoir(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectNoir") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    private func applyVintage(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectInstant") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    private func applyVivid(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIColorControls") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.3, forKey: kCIInputSaturationKey)
        filter.setValue(0.1, forKey: kCIInputBrightnessKey)
        filter.setValue(1.1, forKey: kCIInputContrastKey)
        return filter.outputImage ?? image
    }
    
    private func applyDramatic(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectDramatic") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    private func applyMono(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    private func applyTonal(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectTonal") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    private func applyFade(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectFade") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    private func applyProcess(to image: CIImage) -> CIImage {
        guard let filter = CIFilter(name: "CIPhotoEffectProcess") else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }
    
    // MARK: - Preview Generation
    
    func generateFilterPreviews(for image: UIImage, completion: @escaping ([FilterType: UIImage]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var previews: [FilterType: UIImage] = [:]
            
            // Создаем уменьшенную версию для превью
            let previewSize = CGSize(width: 100, height: 100)
            let previewImage = self.resizeImage(image, to: previewSize)
            
            for filterType in FilterType.allCases {
                if let filteredImage = self.applyFilter(filterType, to: previewImage) {
                    previews[filterType] = filteredImage
                }
            }
            
            DispatchQueue.main.async {
                completion(previews)
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? image
    }
} 