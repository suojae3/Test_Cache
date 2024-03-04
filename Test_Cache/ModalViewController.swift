//
//  ModalViewController.swift
//  Test_Cache
//
//  Created by 신동오 on 2024/03/04.
//

import UIKit


// 어떤 타입으로 캐싱할지도 생각해보기

final class LocalFileManager {
    static let shared = LocalFileManager()
    
    func saveImage(image: UIImage, name: String) {
        
        // 100% 이미지 품질
        guard let data = image.jpegData(compressionQuality: 1.0),
              let path = getPathForImage(name: name)
        else {
            print("error getting data")
            return
        }
        
        do {
            try data.write(to: path)
            print("save succeess")
        } catch let error {
            print("sava error. \(error)")
        }
    }
    
    func getImage(name: String) -> UIImage? {
        guard let path = getPathForImage(name: name)?.path,
              FileManager.default.fileExists(atPath: path)
        else { print("error getting path"); return nil }
        
        return UIImage(contentsOfFile: path)
    }
    
    func getPathForImage(name: String) -> URL? {
        guard let path = FileManager
            .default
            .urls(for: .cachesDirectory, in: .userDomainMask) // 캐시 디렉토리에 만들어짐 -> 다운로드 데이터 캐시저장하기에 적합
            //.urls(for: .documentDirectory, in: .localDomainMask) -> 다큐멘트 디렉토리에 저장, 온보딩할 때 적합
            //.temporaryDirectory -> tmp 디렉토리에 저장되어서 임시값 저장하기에 적함
            .first?
            .appendingPathExtension("\(name).jpg") else {
            print("error getting path")
            return nil
        }
        print(path.absoluteString)
        return path
    }
    
}

final class CacheManager {
    
    static let shaerd = CacheManager()
    private init() {}
    
    let cache = NSCache<NSString, UIImage>()
    
    var imageCache: NSCache<NSString, UIImage> = {
       let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100
        cache.totalCostLimit = 1024 * 1024 * 100  // 메모리에서 지우기전에 홀딩할 수 있는 전체 코스트 -> 100mb
        return cache
    }()
    
    func add(image: UIImage, name: String) {
        imageCache.setObject(image, forKey: name as NSString)
        print("캐시 메모리 저장")
    }
    
    func remove(name: String) {
        imageCache.removeObject(forKey: name as NSString)
        print("캐시메모리 삭제")
    }
    
    func get(name: String) -> UIImage? {
        return imageCache.object(forKey: name as NSString)
    }
}

class ModalViewController: UIViewController {
    
    let testName = "cat"
    let localFilemanager = LocalFileManager.shared
    let cacheManager = CacheManager.shaerd

    
    var userCacheURL: URL?
    let userCacheQueue = OperationQueue()

    @IBOutlet weak var catImageView: UIImageView!

    // MARK: Private Property
    
    private let catUrlString = "https://i.kym-cdn.com/entries/icons/facebook/000/046/895/huh_cat.jpg"
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getImageFromDisk()
        catImageView.image = getFromMemory(name: testName) ?? nil
    }
    
    deinit { print("deinit") }
    
    // MARK: Functions
    
    @IBAction func bringCatButtonTapped(_ sender: UIButton) {
        loadImage(from: catUrlString, into: catImageView)
    }
    
    func loadImage(from urlString: String, into imageView: UIImageView) {
        guard let url = URL(string: urlString) else {
            print("Failed to create URL")
            return
        }
        
        
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to load image: \(error.localizedDescription)")
                return
            }
            print(response)
            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to convert data to image")
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                saveToMemory(image: image, name: testName)
                saveToDisk(image: image)
                imageView.image = image
            }
        }.resume()
    }
}


// MARK: - 캐시 관리
extension ModalViewController {
    
    // MARK: - 디스크에 저장
    func saveToDisk(image: UIImage) {
        localFilemanager.saveImage(image: image, name: testName)
    }
    
    func getImageFromDisk() {
        catImageView.image = localFilemanager.getImage(name: testName)
    }
    
    // MARK: - 인메모리 저장
    func saveToMemory(image: UIImage, name: String) {
        cacheManager.add(image: image, name: name)
    }
    
    func removeFromCache(image: UIImage, name: String) {
        cacheManager.remove(name: name)
        
    }
    
    func getFromMemory(name: String) -> UIImage? {
        return cacheManager.get(name: name)
    }
}
