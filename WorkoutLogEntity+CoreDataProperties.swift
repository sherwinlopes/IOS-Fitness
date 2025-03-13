//
//  WorkoutLogEntity+CoreDataProperties.swift
//  fitness-app
//
//  Created by Lopes, Sherwin Sylvester on 3/13/25.
//
//

import Foundation
import CoreData


extension WorkoutLogEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutLogEntity> {
        return NSFetchRequest<WorkoutLogEntity>(entityName: "WorkoutLogEntity")
    }

    @NSManaged public var calories: Int16
    @NSManaged public var duration: Int16
    @NSManaged public var water: Int16
    @NSManaged public var workoutType: String?

}

extension WorkoutLogEntity : Identifiable {

}
