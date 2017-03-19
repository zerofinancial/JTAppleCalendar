//
//  JTAppleCalendarLayout.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-03-01.
//  Copyright © 2016 OS-Tech. All rights reserved.
//

/// Methods in this class are meant to be overridden and will be called by its collection view to gather layout information.
open class JTAppleCalendarLayout: UICollectionViewLayout, JTAppleCalendarLayoutProtocol {
    
    var shouldClearCacheOnInvalidate = true
    let errorDelta: CGFloat = 0.0000001
    var allowsDateCellStretching = true
    var itemSize: CGSize = CGSize.zero
    var itemSizeWasSet: Bool = false
    var scrollDirection: UICollectionViewScrollDirection = .horizontal
    var maxMissCount: Int = 0
    var cellCache: [Int: [(Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)]] = [:]
    var headerCache: [Int: (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)] = [:]
    var sectionSize: [CGFloat] = []
    var lastWrittenCellAttribute: (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)!
    var isPreparing = true
    var stride: CGFloat = 0
    var cellInset = CGPoint(x: 0, y: 0)
    var headerSizes: [AnyHashable:CGFloat] = [:]
    
    var isCalendarLayoutLoaded: Bool { return !cellCache.isEmpty }
    var layoutIsReadyToBePrepared: Bool {
        return !(!cellCache.isEmpty  || collectionView!.frame.width == 0 || collectionView!.frame.height == 0)
    }
    var monthMap: [Int: Int] = [:]
    var numberOfRows: Int = 0
    var strictBoundaryRulesShouldApply: Bool = false
    var thereAreHeaders: Bool { return !headerSizes.isEmpty }
    
    weak var delegate: JTAppleCalendarDelegateProtocol!
    
    var currentHeader: (section: Int, size: CGSize)? // Tracks the current header size
    var currentCell: (section: Int, width: CGFloat, height: CGFloat)? // Tracks the current cell size
    var contentHeight: CGFloat = 0 // Content height of calendarView
    var contentWidth: CGFloat = 0 // Content wifth of calendarView
    var xCellOffset: CGFloat = 0
    var yCellOffset: CGFloat = 0
    var daysInSection: [Int: Int] = [:] // temporary caching
    var monthInfo: [Month] = []
    
    var testVal: CGFloat = 0
    
    init(withDelegate delegate: JTAppleCalendarDelegateProtocol) {
        super.init()
        self.delegate = delegate
    }
    /// Tells the layout object to update the current layout.
    open override func prepare() {
        if !layoutIsReadyToBePrepared {
            return
        }
        
        setupDataFromDelegate()
        updateLayoutItemSize()
        
        if scrollDirection == .vertical {
            verticalStuff()
        } else {
            horizontalStuff()
        }
        
        // Get rid of header data if dev didnt register headers.
        // The were used for calculation but are not needed to be displayed
        if !thereAreHeaders {
            headerCache.removeAll()
        }
        daysInSection.removeAll() // Clear chache
    }
    
    func setupDataFromDelegate() {
        // get information from the delegate
        strictBoundaryRulesShouldApply = thereAreHeaders || delegate.cachedConfiguration.hasStrictBoundaries
        headerSizes = delegate.sizesForMonthSection()
        numberOfRows = delegate.cachedConfiguration.numberOfRows
        monthMap = delegate.monthMap
        allowsDateCellStretching = delegate.allowsDateCellStretching
        monthInfo = delegate.monthInfo
        scrollDirection = delegate.scrollDirection
        maxMissCount = scrollDirection == .horizontal ? maxNumberOfRowsPerMonth : maxNumberOfDaysInWeek
    }
    
    func indexPath(direction: SegmentDestination, of section:Int, item: Int) -> IndexPath? {
        var retval: IndexPath?
        switch direction {
        case .next:
            if let data = cellCache[section]?.last, data.1 == section, data.0 == item {
                retval = IndexPath(item: data.0, section: data.1)
            } else {
                if let data = cellCache[section]?[item + 1] {
                    retval = IndexPath(item: data.0, section: data.1)
                }
            }
        case .previous:
            if item < 1 {
                if let data = cellCache[section - 1]?.last {
                    retval = IndexPath(item: data.0, section: data.1)
                }
            } else {
                if let data = cellCache[section]?[item - 1] {
                    retval = IndexPath(item: data.0, section: data.1)
                }
            }
        default:
            break
        }
        
        return retval
    }
    
    func horizontalStuff() {
        var section = 0
        var totalDayCounter = 0
        var headerGuide = 0
        let fullSection = numberOfRows * maxNumberOfDaysInWeek
        var extra = 0
        
        for aMonth in monthInfo {
            for numberOfDaysInCurrentSection in aMonth.sections {
                // Generate and cache the headers
                if let aHeaderAttr = determineToApplySupplementaryAttribs(0, section: section) {
                    headerCache[section] = aHeaderAttr
                    if strictBoundaryRulesShouldApply {
                        contentWidth += aHeaderAttr.4 + testVal
                        yCellOffset = aHeaderAttr.5
                    }
                }
                // Generate and cache the cells
                for item in 0..<numberOfDaysInCurrentSection {
                    if let attribute = determineToApplyAttribs(item, section: section) {
                        if cellCache[section] == nil {
                            cellCache[section] = []
                        }
                        cellCache[section]!.append(attribute)
                        lastWrittenCellAttribute = attribute
                        xCellOffset += attribute.4
                        
                        if strictBoundaryRulesShouldApply {
                            headerGuide += 1
                            if numberOfDaysInCurrentSection - 1 == item || headerGuide % maxNumberOfDaysInWeek == 0 {
                                // We are at the last item in the section
                                // && if we have headers
                                headerGuide = 0
                                xCellOffset = 0
                                yCellOffset += attribute.5
                            }
                        } else {
                            totalDayCounter += 1
                            extra += 1
                            if totalDayCounter % fullSection == 0 { // If you have a full section
                                xCellOffset = 0
                                yCellOffset = 0
                                contentWidth += attribute.4 * 7
                                stride = contentWidth
                                sectionSize.append(contentWidth)
                            } else {
                                if totalDayCounter >= delegate.totalDays {
                                    contentWidth += attribute.4 * 7
                                    sectionSize.append(contentWidth)
                                }
                                
                                if totalDayCounter % maxNumberOfDaysInWeek == 0 {
                                    xCellOffset = 0
                                    yCellOffset += attribute.5
                                }
                            }
                        }
                    }
                }
                // Save the content size for each section
                
                if strictBoundaryRulesShouldApply {
                    sectionSize.append(contentWidth)
                    stride = sectionSize[section]
                }
                section += 1
            }
        }
        contentHeight = self.collectionView!.bounds.size.height
    }
    
    func verticalStuff() {
        var section = 0
        var totalDayCounter = 0
        var headerGuide = 0
        for aMonth in monthInfo {
            for numberOfDaysInCurrentSection in aMonth.sections {
                // Generate and cache the headers
                if strictBoundaryRulesShouldApply {
                    if let aHeaderAttr = determineToApplySupplementaryAttribs(0, section: section) {
                        headerCache[section] = aHeaderAttr
                        yCellOffset += aHeaderAttr.5
                        contentHeight += aHeaderAttr.5
                    }
                }
                // Generate and cache the cells
                for item in 0..<numberOfDaysInCurrentSection {
                    if let attribute = determineToApplyAttribs(item, section: section) {
                        if cellCache[section] == nil {
                            cellCache[section] = []
                        }
                        cellCache[section]!.append(attribute)
                        lastWrittenCellAttribute = attribute
                        xCellOffset += attribute.4
                        if strictBoundaryRulesShouldApply {
                            headerGuide += 1
                            if headerGuide % maxNumberOfDaysInWeek == 0 || numberOfDaysInCurrentSection - 1 == item {
                                // We are at the last item in the
                                // section && if we have headers
                                headerGuide = 0
                                xCellOffset = 0
                                yCellOffset += attribute.5
                                contentHeight += attribute.5
                            }
                        } else {
                            totalDayCounter += 1
                            if totalDayCounter % maxNumberOfDaysInWeek == 0 {
                                xCellOffset = 0
                                yCellOffset += attribute.5
                                contentHeight += attribute.5
                            } else if totalDayCounter == delegate.totalDays {
                                contentHeight += attribute.5
                            }
                        }
                    }
                }
                // Save the content size for each section
                sectionSize.append(contentHeight)
                section += 1
            }
        }
        contentWidth = self.collectionView!.bounds.size.width
    }
    
    /// Returns the width and height of the collection view’s contents.
    /// The width and height of the collection view’s contents.
    open override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    /// Returns the layout attributes for all of the cells
    /// and views in the specified rectangle.
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let startSectionIndex = startIndexFrom(rectOrigin: rect.origin)
        // keep looping until there were no interception rects
        var attributes: [UICollectionViewLayoutAttributes] = []
        var beganIntercepting = false
        var missCount = 0
        for sectionIndex in startSectionIndex..<cellCache.count {
            if let validSection = cellCache[sectionIndex], !validSection.isEmpty {
                // Add header view attributes
                if thereAreHeaders {
                    let data = headerCache[sectionIndex]!
                    
                    if CGRect(x: data.2, y: data.3, width: data.4, height: data.5).intersects(rect) {
                        let attrib = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: IndexPath(item: data.0, section: data.1))
                        attributes.append(attrib!)
                    }
                }
                for val in validSection {
                    if CGRect(x: val.2, y: val.3, width: val.4, height: val.5).intersects(rect) {
                        missCount = 0
                        beganIntercepting = true
                        let attrib = layoutAttributesForItem(at: IndexPath(item: val.0, section: val.1))
                        attributes.append(attrib!)
                    } else {
                        missCount += 1
                        // If there are at least 8 misses in a row
                        // since intercepting began, then this
                        // section has no more interceptions.
                        // So break
                        if missCount > maxMissCount && beganIntercepting {
                            break
                        }
                    }
                }
                if missCount > maxMissCount && beganIntercepting {
                    // Also break from outter loop
                    break
                }
            }
        }
        return attributes
    }
    
    /// Returns the layout attributes for the item at the specified index
    /// path. A layout attributes object containing the information to apply
    /// to the item’s cell.
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        // If this index is already cached, then return it else,
        // apply a new layout attribut to it
        if let alreadyCachedCellAttrib = cellAttributeFor(indexPath.item, section: indexPath.section) {
            return alreadyCachedCellAttrib
        }
        return nil//deterimeToApplyAttribs(indexPath.item, section: indexPath.section)
    }
    
    func supplementaryAttributeFor(item: Int, section: Int, elementKind: String) -> UICollectionViewLayoutAttributes? {
        var retval: UICollectionViewLayoutAttributes?
        if let cachedData = headerCache[section] {
            
            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: IndexPath(item: item, section: section))
            attributes.frame = CGRect(x: cachedData.2, y: cachedData.3, width: cachedData.4, height: cachedData.5)
            retval = attributes
        }
        return retval
    }
    func cellAttributeFor(_ item: Int, section: Int) -> UICollectionViewLayoutAttributes? {
        if
            let alreadyCachedCellAttrib = cellCache[section],
            item < alreadyCachedCellAttrib.count,
            item >= 0 {
            
            let cachedValue = alreadyCachedCellAttrib[item]
            
            let attrib = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: item, section: section))
            attrib.frame = CGRect(x: cachedValue.2, y: cachedValue.3, width: cachedValue.4, height: cachedValue.5)
            if cellInset.x > -1, cellInset.y > -1 {
                var frame = attrib.frame.insetBy(dx: cellInset.x, dy: cellInset.y)
                if frame == .null {
                    frame = attrib.frame.insetBy(dx: 0, dy: 0)
                }
                attrib.frame = frame
            }
            return attrib
        }
        return nil
    }
    
    func determineToApplyAttribs(_ item: Int, section: Int) -> (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)? {
        let monthIndex = monthMap[section]!
        let numberOfDays = numberOfDaysInSection(monthIndex)
        // return nil on invalid range
        if !(0...monthMap.count ~= section) || !(0...numberOfDays  ~= item) { return nil }
        
        let size = sizeForitemAtIndexPath(item, section: section)
        return (item, section, xCellOffset + stride, yCellOffset, size.width, size.height)
    }
    
    func determineToApplySupplementaryAttribs(_ item: Int, section: Int) -> (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)? {
        var retval: (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)?
        
        let headerHeight = cachedHeaderHeightForSection(section)
        
        switch scrollDirection {
        case .horizontal:
            let modifiedSize = sizeForitemAtIndexPath(item, section: section)
            retval = (item, section, contentWidth, 0, modifiedSize.width * 7, headerHeight)
        case .vertical:
            // Use the calculaed header size and force the width
            // of the header to take up 7 columns
            // We cache the header here so we dont call the
            // delegate so much
            
            let modifiedSize = (width: collectionView!.frame.width, height: headerHeight)
            retval = (item, section, 0, yCellOffset, modifiedSize.width, modifiedSize.height)
        }
        if retval?.4 == 0, retval?.5 == 0 {
            return nil
        }
        return retval
    }
    
    /// Returns the layout attributes for the specified supplementary view.
    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if let alreadyCachedHeaderAttrib = supplementaryAttributeFor(item: indexPath.item, section: indexPath.section, elementKind: elementKind) {
            return alreadyCachedHeaderAttrib
        }
        
        return nil
    }
    
    func numberOfDaysInSection(_ index: Int) -> Int {
        if let days = daysInSection[index] {
            return days
        }
        let days = monthInfo[index].numberOfDaysInMonthGrid
        daysInSection[index] = days
        return days
    }
    
    func cachedHeaderHeightForSection(_ section: Int) -> CGFloat {
        var retval: CGFloat = 0
        // We look for most specific to less specific
        // Section = specific dates
        // Months = generic months
        // Default = final resort
        
        if let height = headerSizes[section] {
            retval = height
        } else {
            let monthIndex = monthMap[section]!
            let monthName = monthInfo[monthIndex].name
            if let height = headerSizes[monthName] {
                retval = height
            } else if let height = headerSizes["default"] {
                retval = height
            }
        }

        return retval
    }
    
    func sizeForitemAtIndexPath(_ item: Int, section: Int) -> (width: CGFloat, height: CGFloat) {
        if let cachedCell  = currentCell,
            cachedCell.section == section {
            
            if !strictBoundaryRulesShouldApply, scrollDirection == .horizontal,
                !cellCache.isEmpty {
                
                if let x = cellCache[0]?[0] {
                    return (x.4, x.5)
                } else {
                    return (0, 0)
                }
            } else {
                return (cachedCell.width, cachedCell.height)
            }
        }
        
        var size: (width: CGFloat, height: CGFloat) = (itemSize.width, itemSize.height)
        if itemSizeWasSet {
            if scrollDirection == .vertical {
                size.height = itemSize.height
            } else {
                size.width = itemSize.width
                let headerHeight =  strictBoundaryRulesShouldApply ? cachedHeaderHeightForSection(section) : 0
                let currentMonth = monthInfo[monthMap[section]!]
                let recalculatedNumOfRows = allowsDateCellStretching ? CGFloat(currentMonth.maxNumberOfRowsForFull(developerSetRows: numberOfRows)) : CGFloat(maxNumberOfRowsPerMonth)
                size.height = (collectionView!.frame.height - headerHeight) / recalculatedNumOfRows
                currentCell = (section: section, width: size.width, height: size.height)
            }
        } else {
            // Get header size if it already cached
            let headerHeight =  strictBoundaryRulesShouldApply ? cachedHeaderHeightForSection(section) : 0
            var height: CGFloat = 0
            let currentMonth = monthInfo[monthMap[section]!]
            let numberOfRowsForSection: Int
            if allowsDateCellStretching {
                if strictBoundaryRulesShouldApply {
                    numberOfRowsForSection = currentMonth.maxNumberOfRowsForFull(developerSetRows: numberOfRows)
                } else {
                    numberOfRowsForSection = numberOfRows
                }
            } else {
                numberOfRowsForSection = maxNumberOfRowsPerMonth
            }
            height      = (collectionView!.frame.height - headerHeight) / CGFloat(numberOfRowsForSection)
            size.height = height > 0 ? height : 0
            currentCell = (section: section, width: size.width, height: size.height)
        }
        return size
    }
    
    func numberOfRowsForMonth(_ index: Int) -> Int {
        let monthIndex = monthMap[index]!
        return monthInfo[monthIndex].rows
    }
    
    func startIndexFrom(rectOrigin offset: CGPoint) -> Int {
        let key =  scrollDirection == .horizontal ? offset.x : offset.y
        return startIndexBinarySearch(sectionSize, offset: key)
    }
    
    func sizeOfContentForSection(_ section: Int) -> CGFloat {
        switch scrollDirection {
        case .horizontal:
            return cellCache[section]![0].4 * CGFloat(maxNumberOfDaysInWeek)
        case .vertical:
            let headerSizeOfSection = !headerCache.isEmpty ? headerCache[section]!.5 : 0
            return cellCache[section]![0].5 * CGFloat(numberOfRowsForMonth(section)) + headerSizeOfSection
        }
    }
    
    //    func sectionFromRectOffset(_ offset: CGPoint) -> Int {
    //        let theOffet = scrollDirection == .horizontal ? offset.x : offset.y
    //        return sectionFromOffset(theOffet)
    //    }
    
    func sectionFromOffset(_ theOffSet: CGFloat) -> Int {
        var val: Int = 0
        for (index, sectionSizeValue) in sectionSize.enumerated() {
            if abs(theOffSet - sectionSizeValue) < errorDelta {
                continue
            }
            if theOffSet < sectionSizeValue {
                val = index
                break
            }
        }
        return val
    }
    
    func startIndexBinarySearch<T: Comparable>(_ val: [T], offset: T) -> Int {
        if val.count < 3 {
            return 0
        } // If the range is less than 2 just break here.
        var midIndex: Int = 0
        var startIndex = 0
        var endIndex = val.count - 1
        while startIndex < endIndex {
            midIndex = startIndex + (endIndex - startIndex) / 2
            if midIndex + 1  >= val.count || offset >= val[midIndex] &&
                offset < val[midIndex + 1] ||  val[midIndex] == offset {
                break
            } else if val[midIndex] < offset {
                startIndex = midIndex + 1
            } else {
                endIndex = midIndex
            }
        }
        return midIndex
    }
    
    /// Returns an object initialized from data in a given unarchiver.
    /// self, initialized using the data in decoder.
    required public init?(coder aDecoder: NSCoder) {
        delegate = aDecoder.value(forKey: "delegate") as! JTAppleCalendarDelegateProtocol
        cellCache = aDecoder.value(forKey: "delegate") as! [Int : [(Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)]]
        headerCache = aDecoder.value(forKey: "delegate") as! [Int : (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)]
        headerSizes = aDecoder.value(forKey: "delegate") as! [AnyHashable:CGFloat]
        super.init(coder: aDecoder)
    }
    
    /// Returns the content offset to use after an animation
    /// layout update or change.
    /// - Parameter proposedContentOffset: The proposed point for the
    ///   upper-left corner of the visible content
    /// - returns: The content offset that you want to use instead
    open override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        var retval = proposedContentOffset
        
        
        if let lastOffsetIndex = delegate.lastIndexOffset {
            switch lastOffsetIndex.1 {
            case .supplementaryView:
                if let headerAttr = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: lastOffsetIndex.0) {
                    retval = scrollDirection == .horizontal ? CGPoint(x: headerAttr.frame.origin.x, y: 0) : CGPoint(x: 0, y: headerAttr.frame.origin.y)
                }
            case .cell:
                if let cellAttr = layoutAttributesForItem(at: lastOffsetIndex.0) {
                    retval = scrollDirection == .horizontal ? CGPoint(x: cellAttr.frame.origin.x, y: 0) : CGPoint(x: 0, y: cellAttr.frame.origin.y)
                }
            default:
                break
            }
            
            // Floating point issues. number could appear the same, but are not.
            // thereby causing UIScollView to think it has scrolled
            let retvalOffset: CGFloat
            let calendarOffset: CGFloat
            
            switch scrollDirection {
            case .horizontal:
                retvalOffset = retval.x
                calendarOffset = collectionView!.contentOffset.x
            case .vertical:
                retvalOffset = retval.y
                calendarOffset = collectionView!.contentOffset.y
            }
            
            if  abs(retvalOffset - calendarOffset) < errorDelta {
                retval = collectionView!.contentOffset
            }
        }
        return retval
    }
    open override func invalidateLayout() {
        super.invalidateLayout()
        
        if shouldClearCacheOnInvalidate {
            clearCache()
        }
    }

    func updateLayoutItemSize() {
        
        // Default Item height and width
        var height: CGFloat = collectionView!.bounds.size.height / CGFloat(delegate.cachedConfiguration.numberOfRows)
        var width: CGFloat = collectionView!.bounds.size.width / CGFloat(maxNumberOfDaysInWeek)
        
        if itemSizeWasSet { // If delegate item size was set
            if scrollDirection == .horizontal {
                width = delegate.itemSize
            } else {
                height = delegate.itemSize
            }
        }

        itemSize = CGSize(width: width, height: height)
//        print("collectionViewSize ->> \(collectionView!.frame.size)")
    }
    
    
    func clearCache() {
        headerCache.removeAll()
        cellCache.removeAll()
        sectionSize.removeAll()
        currentHeader = nil
        currentCell = nil
        lastWrittenCellAttribute = nil
        xCellOffset = 0
        yCellOffset = 0
        contentHeight = 0
        contentWidth = 0
        stride = 0
    }
}
