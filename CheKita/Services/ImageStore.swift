import UIKit

/// Photo storage for CheKita. **No Firebase Storage is used, so photos cost nothing.**
///
/// Every picked photo is kept twice:
/// - a full-size JPEG in Application Support on this device (sharp, used whenever it exists);
/// - a small JPEG thumbnail encoded as base64 and saved on the Firestore document
///   (`imageData` / `avatarData`), so the photo still appears after a reinstall or on
///   another device. Thumbnails are kept well under Firestore's 1 MB document limit.
final class ImageStore {
    static let shared = ImageStore()

    /// Longest side of the thumbnail stored in Firestore.
    private let thumbnailMaxDimension: CGFloat = 700
    /// Hard ceiling for the encoded thumbnail (bytes) — Firestore documents max out at ~1 MB.
    private let thumbnailMaxBytes = 180_000

    private let folder: URL
    private let cache = NSCache<NSString, UIImage>()

    private init() {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? fm.temporaryDirectory
        folder = base.appendingPathComponent("CheKita/images", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        cache.countLimit = 300
    }

    // MARK: Local files

    /// Resizes, saves as JPEG on this device and returns the stored file name.
    func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = image.resized(maxDimension: 1200)
        guard let jpeg = resized.jpegData(compressionQuality: 0.82) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try jpeg.write(to: folder.appendingPathComponent(name), options: .atomic)
            cache.setObject(resized, forKey: name as NSString)
            return name
        } catch {
            return nil
        }
    }

    func image(named name: String?) -> UIImage? {
        guard let name, !name.isEmpty else { return nil }
        if let cached = cache.object(forKey: name as NSString) { return cached }
        guard let image = UIImage(contentsOfFile: folder.appendingPathComponent(name).path) else { return nil }
        cache.setObject(image, forKey: name as NSString)
        return image
    }

    func data(named name: String?) -> Data? {
        guard let name, !name.isEmpty else { return nil }
        return try? Data(contentsOf: folder.appendingPathComponent(name))
    }

    func delete(_ name: String?) {
        guard let name, !name.isEmpty else { return }
        cache.removeObject(forKey: name as NSString)
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
    }

    // MARK: Firestore thumbnails (base64)

    /// Makes the small base64 thumbnail that is stored on the Firestore document.
    /// Returns nil when the photo can't be shrunk enough to be safe to store.
    func thumbnailBase64(from data: Data, maxDimension: CGFloat? = nil) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let limit = maxDimension ?? thumbnailMaxDimension
        var quality: CGFloat = 0.6
        var resized = image.resized(maxDimension: limit)
        var jpeg = resized.jpegData(compressionQuality: quality)

        // Step the quality (then the size) down until the thumbnail fits comfortably.
        while let candidate = jpeg, candidate.count > thumbnailMaxBytes, quality > 0.25 {
            quality -= 0.15
            jpeg = resized.jpegData(compressionQuality: quality)
        }
        if let candidate = jpeg, candidate.count > thumbnailMaxBytes {
            resized = image.resized(maxDimension: limit * 0.6)
            jpeg = resized.jpegData(compressionQuality: 0.5)
        }
        guard let finalData = jpeg, finalData.count <= thumbnailMaxBytes else { return nil }
        return finalData.base64EncodedString()
    }

    /// Thumbnail for a photo already saved on this device.
    func thumbnailBase64(forFileNamed name: String?, maxDimension: CGFloat? = nil) -> String? {
        guard let data = data(named: name) else { return nil }
        return thumbnailBase64(from: data, maxDimension: maxDimension)
    }

    /// Decodes a stored thumbnail. `cacheKey` keeps repeated list rows cheap —
    /// pass something that changes when the photo changes (e.g. the item's id + updatedAt).
    func image(base64: String?, cacheKey: String? = nil) -> UIImage? {
        guard let base64, !base64.isEmpty else { return nil }
        let key = (cacheKey ?? String(base64.prefix(48)) + "#\(base64.count)") as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let data = Data(base64Encoded: base64), let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    /// Best available photo: this device's copy first, then the Firestore thumbnail, then a bundled asset.
    func bestImage(fileName: String?, base64: String?, assetName: String?, cacheKey: String? = nil) -> UIImage? {
        if let image = image(named: fileName) { return image }
        if let image = image(base64: base64, cacheKey: cacheKey) { return image }
        if let assetName, let image = UIImage(named: assetName) { return image }
        return nil
    }

    func clearMemoryCache() {
        cache.removeAllObjects()
    }
}

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
