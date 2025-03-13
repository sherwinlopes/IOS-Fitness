import CoreData

class CoreDataStack {

    static let shared = CoreDataStack()

    // The container that holds our Core Data model and manages persistent storage
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "fitness_app") // Replace with your model name
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    // The managed object context used to interact with Core Data
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // Save changes to Core Data context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
