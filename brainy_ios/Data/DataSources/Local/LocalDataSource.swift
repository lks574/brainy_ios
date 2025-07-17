import Foundation
import SwiftData

protocol LocalDataSourceProtocol {
    func save<T: PersistentModel>(_ model: T) throws
    func fetch<T: PersistentModel>(_ type: T.Type) throws -> [T]
    func delete<T: PersistentModel>(_ model: T) throws
}

@MainActor
class LocalDataSource: LocalDataSourceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save<T: PersistentModel>(_ model: T) throws {
        modelContext.insert(model)
        try modelContext.save()
    }
    
    func fetch<T: PersistentModel>(_ type: T.Type) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try modelContext.fetch(descriptor)
    }
    
    func delete<T: PersistentModel>(_ model: T) throws {
        modelContext.delete(model)
        try modelContext.save()
    }
}