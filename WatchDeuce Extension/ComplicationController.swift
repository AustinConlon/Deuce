//
//  ComplicationController.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 12/5/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(createTimelineEntry(forComplication: complication, date: Date()))
    }
    
    // MARK: - Private Methods
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, date: date)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template!)
    }
    
    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate? {
        switch complication.family {
        case .graphicCorner:
            return createGraphicCornerTemplate(forDate: date)
        default:
            return nil
        }
    }
    
    private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let imageProvider = CLKFullColorImageProvider(fullColorImage: UIImage(imageLiteralResourceName: <#T##String#>))
        let template = CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: imageProvider)
        template.imageProvider = imageProvider
        return template
    }
}
