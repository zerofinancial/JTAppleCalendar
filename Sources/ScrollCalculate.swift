//
//  ScrollCalculate.swift
//  JTAppleCalendar
//
//  Created by Jay Thomas on 2019-04-27.
//

class ScrollCalculate {
    let currentSection: Int
//    let contentSizeEndOffset: CGFloat
    
    var contentOffset: CGFloat
    var theTargetContentOffset: CGFloat
    var directionVelocity: CGFloat
    let calendarLayout: JTAppleCalendarLayout
    
    
    init(currentSection: Int, contentOffset: CGFloat, theTargetContentOffset: CGFloat, directionVelocity: CGFloat, layout: JTAppleCalendarLayout) {
        self.currentSection = currentSection
        self.contentOffset = contentOffset
        self.theTargetContentOffset = theTargetContentOffset
        self.directionVelocity = directionVelocity
        self.calendarLayout = layout
    }
    

}
