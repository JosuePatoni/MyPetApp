import CryptoKit
import Foundation
import Observation

/// The album lives in Application Support, outside the SwiftData store.
@MainActor @Observable
final class PetAlbumStore {
    static let shared = PetAlbumStore()

    struct Photo: Codable, Identifiable {
        let id: UUID
        var title: String
        var file: UUID
    }

    struct Album: Codable {
        var photos: [Photo] = []
        var cover: UUID?
        var originalDigest: Data?
    }

    private(set) var revision = 0
    private let fm = FileManager.default
    private let cache = NSCache<NSURL, NSData>()

    @ObservationIgnored private var albums: [UUID: Album] = [:]

    private init() {
        cache.totalCostLimit = 12 * 1024 * 1024
    }

    private func folder(_ petID: UUID) -> URL {
        URL.applicationSupportDirectory.appending(path: "MyPetAlbums").appending(path: petID.uuidString)
    }

    func read(_ petID: UUID) throws -> Album {
        _ = revision
        if let album = albums[petID] { return album }
        let index = folder(petID).appending(path: "album.json")
        do {
            let album = try JSONDecoder().decode(Album.self, from: Data(contentsOf: index))
            albums[petID] = album
            return album
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            let empty = Album()
            albums[petID] = empty
            return empty
        }
    }

    func image(_ photo: Photo, petID: UUID) throws -> Data {
        let url = folder(petID).appending(path: photo.file.uuidString + ".jpg")
        if let data = cache.object(forKey: url as NSURL) { return data as Data }
        let data = try Data(contentsOf: url)
        cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
        return data
    }

    private func digest(_ data: Data?) -> Data? {
        data.map { Data(SHA256.hash(data: $0)) }
    }

    func currentCover(_ album: Album, pet: Pet) -> UUID? {
        guard let cover = album.cover, album.originalDigest == digest(pet.photoData) else { return nil }
        return cover
    }

    func portrait(of pet: Pet) -> Data? {
        guard let album = try? read(pet.uuid), let id = currentCover(album, pet: pet),
              let photo = album.photos.first(where: { $0.id == id }),
              let data = try? image(photo, petID: pet.uuid) else { return pet.photoData }
        return data
    }

    func save(id: UUID, title: String, newJPEG: Data?, makeCover: Bool, pet: Pet) throws {
        var album = try read(pet.uuid)
        let dir = folder(pet.uuid)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let old = album.photos.first { $0.id == id }
        let file = newJPEG == nil ? old?.file : UUID()
        guard let file else { throw CocoaError(.fileReadNoSuchFile) }
        let url = dir.appending(path: file.uuidString + ".jpg")
        try newJPEG?.write(to: url, options: .atomic)
        let item = Photo(id: id, title: title, file: file)
        if let index = album.photos.firstIndex(where: { $0.id == id }) {
            album.photos[index] = item
        } else {
            album.photos.insert(item, at: 0)
        }
        if makeCover {
            album.cover = id
            album.originalDigest = digest(pet.photoData)
        } else if album.cover == id {
            album.cover = nil
            album.originalDigest = nil
        }
        do {
            try commit(album, petID: pet.uuid)
        } catch {
            if newJPEG != nil { try? fm.removeItem(at: url) }
            throw error
        }
        if let old, old.file != file { removeFile(old, in: dir) }
    }

    func delete(_ photo: Photo, petID: UUID) throws {
        var album = try read(petID)
        album.photos.removeAll { $0.id == photo.id }
        if album.cover == photo.id { album.cover = nil; album.originalDigest = nil }
        let dir = folder(petID)
        try commit(album, petID: petID)
        removeFile(photo, in: dir)
    }

    func removeAlbum(for id: UUID) throws {
        let dir = folder(id)
        if fm.fileExists(atPath: dir.path) { try fm.removeItem(at: dir) }
        albums[id] = nil
        revision += 1
    }

    private func commit(_ album: Album, petID: UUID) throws {
        let dir = folder(petID)
        try JSONEncoder().encode(album).write(to: dir.appending(path: "album.json"), options: .atomic)
        albums[petID] = album
        revision += 1
    }

    private func removeFile(_ photo: Photo, in dir: URL) {
        let url = dir.appending(path: photo.file.uuidString + ".jpg")
        cache.removeObject(forKey: url as NSURL)
        try? fm.removeItem(at: url)
    }
}
