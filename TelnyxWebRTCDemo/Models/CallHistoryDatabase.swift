//
//  CallHistoryDatabase.swift
//  TelnyxWebRTCDemo
//
//  Created by AI SWE Agent on 02/06/2025.
//  Copyright © 2025 Telnyx LLC. All rights reserved.
//

import Foundation
import CoreData
import Combine

/// Singleton database manager for call history operations
public class CallHistoryDatabase: ObservableObject {
    
    /// Shared singleton instance
    public static let shared = CallHistoryDatabase()
    
    /// Published property to notify UI of changes
    @Published public var callHistory: [CallHistoryEntity] = []
    
    /// Maximum number of call history entries per profile
    private let maxHistoryCount = 20
    
    /// Core Data persistent container
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AppModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("CallHistoryDatabase: Failed to load Core Data stack: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    /// Main context for UI operations
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    /// Background context for database operations
    private var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    private init() {
        loadCallHistory()
    }
    
    // MARK: - Public Methods
    
    /// Add a new call history entry
    /// - Parameters:
    ///   - callId: Unique identifier for the call
    ///   - phoneNumber: Phone number or SIP URI
    ///   - callerName: Display name (optional)
    ///   - direction: Call direction (incoming/outgoing)
    ///   - duration: Call duration in seconds
    ///   - status: Final call status
    ///   - profileId: Profile identifier
    ///   - metadata: Additional metadata (optional)
    public func addCallHistoryEntry(
        callId: UUID,
        phoneNumber: String,
        callerName: String? = nil,
        direction: CallDirection,
        duration: Int32 = 0,
        status: CallStatus,
        profileId: String,
        metadata: String? = nil
    ) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            // Create the entry in the background context
            let entry = CallHistoryEntity(context: self.backgroundContext)
            // Check that the object is valid (not deleted) before mutating it
             if !entry.isDeleted {
                 // Safe to mutate
                 print("Entering mutation for: \(entry)")
                 entry.callId = callId
                 entry.phoneNumber = phoneNumber
                 entry.callerName = callerName
                 entry.direction = direction.rawValue
                 entry.timestamp = Date()
                 entry.duration = duration
                 entry.callStatus = status.rawValue
                 entry.profileId = profileId
                 entry.metadata = metadata
                 print("Entering mutation for: \(entry)")

             } else {
                 print("Attempted to mutate a deleted object: \(entry)")
             }

            // Save context in the background
            self.saveContext(self.backgroundContext)
            
        
            
            // Safely update the main thread UI
            DispatchQueue.main.async {
                //self.loadCallHistory()
            }
        }
    }
    
    /// Update an existing call history entry
    /// - Parameters:
    ///   - callId: Call identifier to update
    ///   - duration: Updated duration
    ///   - status: Updated status
    public func updateCallHistoryEntry(callId: UUID, duration: Int32? = nil, status: CallStatus? = nil) {
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<CallHistoryEntity> = CallHistoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "callId == %@", callId as CVarArg)
            
            do {
                let entries = try self.backgroundContext.fetch(request)
                if let entry = entries.first {
                    if let duration = duration {
                        entry.duration = duration
                    }
                    if let status = status {
                        entry.callStatus = status.rawValue
                    }
                    self.saveContext(self.backgroundContext)
                    
                    DispatchQueue.main.async {
                        self.loadCallHistory()
                    }
                }
            } catch {
                print("CallHistoryDatabase: Failed to update call history entry: \(error)")
            }
        }
    }
    
    /// Get call history for a specific profile
    /// - Parameter profileId: Profile identifier
    /// - Returns: Array of call history entries
    public func getCallHistory(for profileId: String) -> [CallHistoryEntity] {
        let request: NSFetchRequest<CallHistoryEntity> = CallHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "profileId == %@", profileId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = maxHistoryCount
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("CallHistoryDatabase: Failed to fetch call history: \(error)")
            return []
        }
    }
    
    /// Get all call history entries
    /// - Returns: Array of all call history entries
    public func getAllCallHistory() -> [CallHistoryEntity] {
        let request: NSFetchRequest<CallHistoryEntity> = CallHistoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let call = try viewContext.fetch(request)
            print("\(call)")
            return call
        } catch {
            print("CallHistoryDatabase: Failed to fetch all call history: \(error)")
            return []
        }
    }
    
    /// Clear call history for a specific profile
    /// - Parameter profileId: Profile identifier
    public func clearCallHistory(for profileId: String) {
        return
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<CallHistoryEntity> = CallHistoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "profileId == %@", profileId)
            
            do {
                let entries = try self.backgroundContext.fetch(request)
                for entry in entries {
                    self.backgroundContext.delete(entry)
                }
                self.saveContext(self.backgroundContext)
                
                DispatchQueue.main.async {
                    self.loadCallHistory()
                }
            } catch {
                print("CallHistoryDatabase: Failed to clear call history: \(error)")
            }
        }
    }
    
    /// Delete a specific call history entry
    /// - Parameter callId: Call identifier to delete
    public func deleteCallHistoryEntry(callId: UUID) {
        return
        backgroundContext.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<CallHistoryEntity> = CallHistoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "callId == %@", callId as CVarArg)
            
            do {
                let entries = try self.backgroundContext.fetch(request)
                for entry in entries {
                    self.backgroundContext.delete(entry)
                }
                self.saveContext(self.backgroundContext)
                
                DispatchQueue.main.async {
                    self.loadCallHistory()
                }
            } catch {
                print("CallHistoryDatabase: Failed to delete call history entry: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load call history and update published property
    private func loadCallHistory() {
        callHistory = getAllCallHistory()
    }
    
    /// Save the managed object context
    /// - Parameter context: Context to save
    private func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("CallHistoryDatabase: Failed to save context: \(error)")
            }
        }
    }
    
    /// Enforce the maximum history limit for a profile
    /// - Parameter profileId: Profile identifier
    private func enforceHistoryLimit(for profileId: String) {
        let request: NSFetchRequest<CallHistoryEntity> = CallHistoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "profileId == %@", profileId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let entries = try backgroundContext.fetch(request)
            if entries.count > maxHistoryCount {
                let entriesToDelete = Array(entries.dropFirst(maxHistoryCount))
                for entry in entriesToDelete {
                    backgroundContext.delete(entry)
                }
                saveContext(backgroundContext)
            }
        } catch {
            print("CallHistoryDatabase: Failed to enforce history limit: \(error)")
        }
    }
}


extension CallHistoryEntity {
    
    /// Convenience computed property for call direction
    public var isIncoming: Bool {
        return direction == "incoming"
    }

    /// Convenience computed property for call direction
    public var isOutgoing: Bool {
        return direction == "outgoing"
    }
    
    /// Formatted duration string (e.g., "1:23")
     public var formattedDuration: String {
         let minutes = duration / 60
         let seconds = duration % 60
         return String(format: "%d:%02d", minutes, seconds)
     }

     /// Formatted timestamp for display
     public var formattedTimestamp: String {
         let formatter = DateFormatter()
         formatter.dateStyle = .short
         formatter.timeStyle = .short
         return formatter.string(from: timestamp ?? Date())
     }
}
