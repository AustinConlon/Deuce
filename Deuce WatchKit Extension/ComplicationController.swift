//
//  ComplicationController.swift
//  Test WatchKit Extension
//
//  Created by Austin Conlon on 5/1/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
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
        switch complication.family {
        case .modularSmall:
            let simpleImage = CLKComplicationTemplateModularSmallSimpleImage()
            simpleImage.imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Complication/Modular"))
            simpleImage.tintColor = UIColor(red:0.27, green:0.79, blue:0.26, alpha:1.0)
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: simpleImage)
            handler(entry)
        case .utilitarianSmall:
            let square = CLKComplicationTemplateUtilitarianSmallSquare()
            square.imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "Complication/Utilitarian"))
            square.tintColor = UIColor(red:0.27, green:0.79, blue:0.26, alpha:1.0)
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: square)
            handler(entry)
        case .utilitarianLarge:
            let flat = CLKComplicationTemplateUtilitarianLargeFlat()
            flat.textProvider = CLKSimpleTextProvider(text: "Play Tennis")
            let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: flat)
            handler(entry)
        default:
            handler(nil)
        }
    }
}
