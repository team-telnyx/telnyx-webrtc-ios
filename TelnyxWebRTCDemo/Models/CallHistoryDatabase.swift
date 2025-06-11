import Foundation
import CoreData
import Combine

class CallHistoryDatabase: ObservableObject {
    
    // Singleton instance for managing the database
    public static let shared = CallHistoryDatabase()
    
    // Publisher for call history
    @Published public var callHistory: [CallHistoryEntry] = []
    
    // Create the persistent container here
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AppModel")  // Replace with your actual model name
        container.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        }
        return container
    }()
    

    
    private lazy var context: NSManagedObjectContext = {
        let bgContext = self.persistentContainer.newBackgroundContext()
        bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        bgContext.automaticallyMergesChangesFromParent = true
        return bgContext
    }()
    
    // Maximum number of call history entries per profile
    private let maxHistoryCount = 100
    
    // Function to add a new call history entry
    func createCallHistoryEntry(callerName: String, callId: UUID, callStatus: String, direction: String, metadata: String, phoneNumber: String, profileId: String, timestamp: Date, completion: @escaping (Bool) -> Void) {
        
        let fetchRequest: NSFetchRequest<CallHistoryEntry> = CallHistoryEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "callId == %@", callId as CVarArg)
        
        // Use viewContext for the fetch and insertion
        context.perform {
            do {
                let existingRecords = try self.context.fetch(fetchRequest)
                
                if existingRecords.isEmpty {
                    // Create a new entry if it doesn't exist
                    let callHistoryEntry = CallHistoryEntry(context: self.context)
                    callHistoryEntry.callerName = callerName
                    callHistoryEntry.callId = callId
                    callHistoryEntry.callStatus = callStatus
                    callHistoryEntry.direction = direction
                    callHistoryEntry.metadata = metadata
                    callHistoryEntry.phoneNumber = phoneNumber
                    callHistoryEntry.profileId = profileId
                    callHistoryEntry.timestamp = timestamp
                    
                    // Save the context
                    try self.context.save()
                    
                    // Refresh the call history
                    self.fetchCallHistoryFiltered(by:profileId)
                    
                    completion(true)
                } else {
                    print("A call history entry with the same callId already exists.")
                    completion(false)
                }
            } catch {
                print("Core Data operation failed: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    
    // Function to fetch filtered call history by profileId
    func fetchCallHistoryFiltered(by profileId: String){
        let fetchRequest: NSFetchRequest<CallHistoryEntry> = CallHistoryEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profileId == %@", profileId)
        
        var filteredEntries: [CallHistoryEntry] = []
        
        context.perform {
            do {
                filteredEntries = try self.context.fetch(fetchRequest)
                DispatchQueue.main.async {
                    self.callHistory = filteredEntries  // Update the @Published callHistory property
                }
            } catch {
                print("Failed to fetch filtered call history entries: \(error.localizedDescription)")
            }
        }
        
    }
    
    // Function to update a call history entry's duration or status by callId
    public func updateCallHistoryEntry(callId: UUID, duration: Int32? = nil, status: CallStatus? = nil, completion: @escaping (Bool) -> Void) {
        let fetchRequest: NSFetchRequest<CallHistoryEntry> = CallHistoryEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "callId == %@", callId as CVarArg)
        
        context.perform {
            do {
                let entries = try self.context.fetch(fetchRequest)
                
                if let entry = entries.first {
                    // Update the duration if provided
                    if let duration = duration {
                        entry.duration = duration
                    }
                    
                    // Update the status if provided
                    if let status = status {
                        entry.callStatus = status.rawValue  // Assuming CallStatus is an enum with raw values
                    }
                    
                    // Save the changes in the context
                    try self.context.save()
                    completion(true)
                } else {
                    print("No call history entry found with the given callId.")
                    completion(false)
                }
            } catch {
                print("Failed to update call history entry: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    // Function to delete a specific call history entry by callId
    public func deleteCallHistoryEntry(callId: UUID,profileId:String) {
        let fetchRequest: NSFetchRequest<CallHistoryEntry> = CallHistoryEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "callId == %@", callId as CVarArg)
        
        context.perform {
            do {
                let entries = try self.context.fetch(fetchRequest)
                if let entry = entries.first {
                    self.context.delete(entry)
                    try self.context.save()
                    self.fetchCallHistoryFiltered(by: profileId)
                } else {
                    print("No call history entry found with the given callId.")
                }
            } catch {
                print("Failed to delete call history entry: \(error.localizedDescription)")
            }
        }
    }
    
    // Function to clear call history for a specific profileId
    public func clearCallHistory(for profileId: String) {
        let fetchRequest: NSFetchRequest<CallHistoryEntry> = CallHistoryEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "profileId == %@", profileId)
        
        context.perform {
            do {
                let entries = try self.context.fetch(fetchRequest)
                for entry in entries {
                    self.context.delete(entry)
                }
                try self.context.save()
                self.fetchCallHistoryFiltered(by: profileId) // Refresh the callHistory property
            } catch {
                print("Failed to clear call history for profileId \(profileId): \(error.localizedDescription)")
            }
        }
    }
}
