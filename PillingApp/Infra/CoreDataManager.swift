import CoreData
import RxSwift

final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let appGroupIdentifier = "group.app.Pilltastic.Pilling"
    
    private init() {
    }
    
    // MARK: - 코어데이터 스택
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "PillingApp")
        
        /// 앱과 위젯이 같은 DB를 공유하도록 같은 앱그룹을 공유함
        if let storeURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )?.appendingPathComponent("PillingApp.sqlite") {
            let description = NSPersistentStoreDescription(url: storeURL)
            /// 자동 마이그레이션 옵션
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            container.persistentStoreDescriptions = [description]
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private func newBackgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    // MARK: - CRUD 함수들
    
    func save() -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.viewContext
            
            context.perform {
                guard context.hasChanges else {
                    observer.onNext(())
                    observer.onCompleted()
                    return
                }
                
                do {
                    try context.save()
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    observer.onError(CoreDataError.saveFailed(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func fetch<T: NSManagedObject>(
        entityType: T.Type,
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil
    ) -> Observable<[T]> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.viewContext
            
            context.perform {
                let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entityType))
                fetchRequest.predicate = predicate
                fetchRequest.sortDescriptors = sortDescriptors
                
                do {
                    let results = try context.fetch(fetchRequest)
                    observer.onNext(results)
                    observer.onCompleted()
                } catch {
                    observer.onError(CoreDataError.fetchFailed(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func delete<T: NSManagedObject>(_ object: T) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }
            
            let context = self.viewContext
            
            context.perform {
                context.delete(object)
                
                do {
                    try context.save()
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    observer.onError(CoreDataError.deleteFailed(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    func deleteAll<T: NSManagedObject>(entityType: T.Type) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(CoreDataError.contextNotAvailable)
                return Disposables.create()
            }

            let context = self.viewContext

            context.perform {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entityType))
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

                do {
                    try context.execute(deleteRequest)
                    try context.save()
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    observer.onError(CoreDataError.deleteFailed(error))
                }
            }

            return Disposables.create()
        }
    }

    func deleteAllDataSync() {
        let context = viewContext

        context.performAndWait {
            let entities = ["PillRecordEntity", "PillCycleEntity"]

            for entityName in entities {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                deleteRequest.resultType = .resultTypeObjectIDs

                do {
                    let result = try context.execute(deleteRequest) as? NSBatchDeleteResult
                    let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
                    let changes = [NSDeletedObjectsKey: objectIDArray]
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                } catch {
                    print("Failed to delete \(entityName): \(error)")
                }
            }

            do {
                try context.save()
            } catch {
                print("Failed to save context after deletion: \(error)")
            }
        }
    }
}
