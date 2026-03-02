import CoreData
import CloudKit
import Foundation

/// Manages the Core Data stack with CloudKit sync support
final class PersistenceController {
    static let shared = PersistenceController()

    // MARK: - Core Data Stack

    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "StreamFlow", managedObjectModel: self.model)

        // Configure for CloudKit sync
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

            // Set CloudKit container identifier
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.streamflow.habits"
            )
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                // In production, handle this error appropriately
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true

        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Core Data Model

    private lazy var model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        // Define Habit entity
        let habitEntity = NSEntityDescription()
        habitEntity.name = "CDHabit"
        habitEntity.managedObjectClassName = "CDHabit"

        let habitAttributes: [(String, NSAttributeType, Any?, Bool)] = [
            ("id", .UUIDAttributeType, nil, false),
            ("name", .stringAttributeType, nil, false),
            ("createdAt", .dateAttributeType, Date(), false),
            ("reminderTime", .dateAttributeType, nil, true),
            ("reminderEnabled", .booleanAttributeType, false, false),
            ("color", .stringAttributeType, "blue", false),
            ("icon", .stringAttributeType, "star.fill", false),
            ("isArchived", .booleanAttributeType, false, false)
        ]

        habitEntity.properties = habitAttributes.map { name, type, defaultValue, isOptional in
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = isOptional
            if let defaultValue = defaultValue {
                attribute.defaultValue = defaultValue
            }
            return attribute
        }

        // Define HabitCompletion entity
        let completionEntity = NSEntityDescription()
        completionEntity.name = "CDHabitCompletion"
        completionEntity.managedObjectClassName = "CDHabitCompletion"

        let completionAttributes: [(String, NSAttributeType, Any?, Bool)] = [
            ("id", .UUIDAttributeType, nil, false),
            ("completedAt", .dateAttributeType, Date(), false),
            ("note", .stringAttributeType, nil, true)
        ]

        completionEntity.properties = completionAttributes.map { name, type, defaultValue, isOptional in
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = isOptional
            if let defaultValue = defaultValue {
                attribute.defaultValue = defaultValue
            }
            return attribute
        }

        // Define relationships
        let habitToCompletions = NSRelationshipDescription()
        habitToCompletions.name = "completions"
        habitToCompletions.destinationType = completionEntity
        habitToCompletions.isToMany = true
        habitToCompletions.deleteRule = .cascadeDeleteRule

        let completionToHabit = NSRelationshipDescription()
        completionToHabit.name = "habit"
        completionToHabit.destinationType = habitEntity
        completionToHabit.isToMany = false
        completionToHabit.deleteRule = .nullifyDeleteRule
        completionToHabit.isOptional = false

        // Set inverse relationships
        habitToCompletions.inverseRelationship = completionToHabit
        completionToHabit.inverseRelationship = habitToCompletions

        // Add relationships to entities
        habitEntity.properties.append(habitToCompletions)
        completionEntity.properties.append(completionToHabit)

        // Add entities to model
        model.entities = [habitEntity, completionEntity]

        return model
    }()

    // MARK: - Preview Support

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.viewContext

        // Create sample habits for previews
        for i in 0..<5 {
            let habit = CDHabit(context: viewContext)
            habit.id = UUID()
            habit.name = "Sample Habit \(i + 1)"
            habit.createdAt = Date()
            habit.color = ["blue", "green", "orange", "purple", "pink"][i]
            habit.icon = ["star.fill", "heart.fill", "bolt.fill", "leaf.fill", "drop.fill"][i]
            habit.reminderEnabled = false
            habit.isArchived = false

            // Add some completions
            for j in 0..<Int.random(in: 1...10) {
                let completion = CDHabitCompletion(context: viewContext)
                completion.id = UUID()
                completion.completedAt = Date().addingTimeInterval(TimeInterval(-j * 86400))
                completion.habit = habit
            }
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to save preview data: \(error)")
        }

        return controller
    }()

    // MARK: - Init

    init(inMemory: Bool = false) {
        if inMemory {
            persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
    }

    // MARK: - Save

    func save() {
        guard viewContext.hasChanges else { return }

        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}