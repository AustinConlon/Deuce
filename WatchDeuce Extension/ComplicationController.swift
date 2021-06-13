//
//  ComplicationController.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/4/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import ClockKit


class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward, .backward])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        handler(createTimelineEntry(forComplication: complication, date: Date()))
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Private Methods
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, date: date)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        
        switch (complication.family, complication.identifier) {
        case (.graphicCorner, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.modularSmall, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.modularLarge, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.utilitarianSmall, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.utilitarianSmallFlat, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.utilitarianLarge, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.circularSmall, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.extraLarge, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.graphicBezel, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.graphicCircular, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.graphicRectangular, _):
            return createGraphicCornerTemplate(forDate: date)
        case (.graphicExtraLarge, _):
            return createGraphicCornerTemplate(forDate: date)
        @unknown default:
            fatalError("*** Unknown Family and identifier pair: (\(complication.family), \(complication.identifier)) ***")
        }
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
    // MARK: - Graphic Corner Template
    
    private func createGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        let imageProvider = CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "Complication/Graphic Corner"))
        
        // Create the template using the provider.
        return CLKComplicationTemplateGraphicCornerCircularImage(imageProvider: imageProvider)
    }
}
