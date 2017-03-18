//
//  JTAppleCalendarDelegateProtocol.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-09-19.
//
//


protocol JTAppleCalendarDelegateProtocol: class {
    var isCalendarLayoutLoaded: Bool {get}
    var itemSize: CGFloat {get set}
    var cachedConfiguration: ConfigurationParameters! {get set}
    var monthInfo: [Month] {get set}
    var monthMap: [Int: Int] {get set}
    var totalDays: Int {get}
    var lastIndexOffset: (IndexPath, UICollectionElementCategory)? {get set}
    var allowsDateCellStretching: Bool {get set}
    
    func cachedDate() -> (start: Date, end: Date, calendar: Calendar)
    func numberOfMonthsInCalendar() -> Int
    func rowsAreStatic() -> Bool
    func sizesForMonthSection() -> [AnyHashable:CGFloat]?
    
    func targetPointForItemAt(indexPath: IndexPath) -> CGPoint?
    func pathsFromDates(_ dates: [Date]) -> [IndexPath]

}

extension JTAppleCalendarView: JTAppleCalendarDelegateProtocol {
    func cachedDate() -> (start: Date, end: Date, calendar: Calendar) {
        return (start: startDateCache,
                end: endDateCache,
                calendar: calendar)
    }
    

    
    
    func numberOfMonthsInCalendar() -> Int {
        return numberOfMonths
    }
    func calendarSizeForMonths(_ calendar: JTAppleCalendarView?) -> MonthSize {
        return calendarDelegate!.calendarSizeForMonths(self)
    }
    
//    func referenceSizeForHeaderInSection(_ section: Int) -> CGSize {
//        return calendarViewHeaderSizeForSection(section)
//    }
    
    func rowsAreStatic() -> Bool {
        // jt101 is the inDateCellGeneration check needed? because tillEndOfGrid will always compenste
        return cachedConfiguration.generateInDates != .off && cachedConfiguration.generateOutDates == .tillEndOfGrid
    }
}
