//
//  ScrollViewDelegates.swift
//  PoJTAppleCalendards
//
//  Created by JayT on 2016-08-08.
//
//

extension JTAppleCalendarView: UIScrollViewDelegate {
    /// Tells the delegate when the user finishes scrolling the content.
    public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let saveLastContentOffset = { self.lastSavedContentOffset = self.direction == .Horizontal ? targetContentOffset.memory.x : targetContentOffset.memory.y }
        
        var contentOffset: CGFloat = 0,
        theTargetContentOffset: CGFloat = 0,
        directionVelocity: CGFloat = 0,
        contentSize: CGFloat = 0,
        frameSize: CGFloat = 0
        
        let calendarLayout = (calendarView.collectionViewLayout as! JTAppleCalendarLayoutProtocol)
        
        
        
        if direction == .Horizontal {
            contentOffset = scrollView.contentOffset.x
            theTargetContentOffset = targetContentOffset.memory.x
            directionVelocity = velocity.x
            contentSize = scrollView.contentSize.width
            frameSize = scrollView.frame.size.width
        } else {
            contentOffset = scrollView.contentOffset.y
            theTargetContentOffset = targetContentOffset.memory.y
            directionVelocity = velocity.y
            contentSize = scrollView.contentSize.height
            frameSize = scrollView.frame.size.height
        }
        
        let isScrollingForward = {return directionVelocity > 0 || contentOffset > self.lastSavedContentOffset}
        let isScrollingBackward = {return directionVelocity < 0 || contentOffset < self.lastSavedContentOffset}
        let isNotScrolling = {return contentOffset == self.lastSavedContentOffset}
        
        let theCurrentSection = currentSectionPage
        
        let setTargetContentOffset = {(finalOffset: CGFloat) -> Void in
            if self.direction == .Horizontal {
                targetContentOffset.memory.x = finalOffset
            } else {
                targetContentOffset.memory.y = finalOffset
            }
        }
        
        let calculatedCurrentFixedContentOffsetFrom = {(interval: CGFloat)->CGFloat in
            if isScrollingForward() {
                return ceil(contentOffset / interval) * interval
            } else if isScrollingBackward(){
                return floor(contentOffset / interval) * interval
            }
            return contentOffset
        }
        
        let calculatedFutureFixedContentOffsetFrom = {(interval: CGFloat, futureOffset:CGFloat)->CGFloat in
            if isScrollingForward() {
                return ceil(futureOffset / interval) * interval
            } else if isScrollingBackward(){
                return floor(futureOffset / interval) * interval
            }
            return futureOffset
        }
        
        
        switch scrollingMode {
        case let .StopAtEach(customInterval: interval):
            let calculatedOffset = calculatedCurrentFixedContentOffsetFrom(interval)
            setTargetContentOffset(calculatedOffset)
        case .StopAtEachCalendarFrameWidth:
            let interval = self.direction == .Horizontal ? scrollView.frame.width : scrollView.frame.height
            let calculatedOffset = calculatedCurrentFixedContentOffsetFrom(interval)
            setTargetContentOffset(calculatedOffset)
        case .StopAtEachSection:
            var calculatedOffSet: CGFloat = 0
            if self.direction == .Horizontal || (self.direction == .Vertical && self.registeredHeaderViews.count < 1) {
                // Horizontal has a fixed width. Vertical with no header has fixed height
                let interval = calendarLayout.sizeOfContentForSection(theCurrentSection)
                calculatedOffSet = calculatedCurrentFixedContentOffsetFrom(interval)
            } else {
                // Vertical with headers have variable heights. It needs to be calculated
                let currentScrollOffset = scrollView.contentOffset.y
                let currentScrollSection = calendarLayout.sectionFromOffset(currentScrollOffset)
                let attrib: UICollectionViewLayoutAttributes
                var sectionSize: CGFloat = 0
                
                if isScrollingForward() {
                    sectionSize = calendarLayout.sectionSize[currentScrollSection]
                    calculatedOffSet = sectionSize
                } else if isScrollingBackward() {
                    if currentScrollSection - 1  >= 0 {
                        calculatedOffSet = calendarLayout.sectionSize[currentScrollSection - 1]
                    }
                }
            }
            setTargetContentOffset(calculatedOffSet)
        case .NonStopToSection, .NonStopToCell, .NonStopTo:
            
            let diff = abs(theTargetContentOffset - contentOffset)
            var calculatedOffSet = contentOffset
            
            switch scrollingMode {
            case let .NonStopToSection(resistance):
                let futureSection = calendarLayout.sectionFromOffset(theTargetContentOffset)
                let interval = calendarLayout.sizeOfContentForSection(futureSection)
                let diffResistance = diff * resistance
                if isScrollingForward() {
                    let recalcOffsetAfterResistanceApplied = theTargetContentOffset - diffResistance
                    calculatedOffSet = ceil(recalcOffsetAfterResistanceApplied / interval) * interval
                } else if isScrollingBackward() {
                    let recalcOffsetAfterResistanceApplied = theTargetContentOffset + diffResistance
                    calculatedOffSet = floor(recalcOffsetAfterResistanceApplied / interval) * interval
                }
                
                if self.direction == .Vertical && self.registeredHeaderViews.count > 0 { // If we have a vertical direction, we need to account for landing on a header
                    let stopSection = calendarLayout.sectionFromOffset(calculatedOffSet) - 1
                    calculatedOffSet = stopSection < 0 ? 0 : calendarLayout.sectionSize[stopSection]
                }
                
                setTargetContentOffset(calculatedOffSet)

            case let .NonStopToCell(resistance):
                
                let sizeOfcell: CGFloat
                var interval: CGFloat = 0
                var finalValue: CGFloat
                if direction == .Horizontal {
                    let section = calendarLayout.sectionFromOffset(targetContentOffset.memory.x)
                    interval = calendarLayout.cellCache[section]![0].frame.width
                    let diff = abs(theTargetContentOffset - contentOffset)
                    let diffResistance = diff * resistance

                    let recalcOffsetAfterResistanceApplied: CGFloat

                    if isScrollingForward() {
                        recalcOffsetAfterResistanceApplied = theTargetContentOffset - diffResistance
                        finalValue = ceil(recalcOffsetAfterResistanceApplied / interval) * interval
                    } else {
                        recalcOffsetAfterResistanceApplied = theTargetContentOffset + diffResistance
                        finalValue = floor(recalcOffsetAfterResistanceApplied / interval) * interval
                    }
                    setTargetContentOffset(finalValue)
                } else {
                    let section = calendarLayout.sectionFromOffset(targetContentOffset.memory.y)
                    interval = calendarLayout.cellCache[section]![0].frame.height
                    let diff = abs(theTargetContentOffset - contentOffset)
                    let diffResistance = diff * resistance
                    let recalcOffsetAfterResistanceApplied: CGFloat
                    
                    var finalValue: CGFloat
                    if isScrollingBackward() {
                        recalcOffsetAfterResistanceApplied = theTargetContentOffset + diffResistance
                        finalValue = floor(recalcOffsetAfterResistanceApplied / interval) * interval
                        
                    } else {
                        recalcOffsetAfterResistanceApplied = theTargetContentOffset - diffResistance
                        finalValue = ceil(recalcOffsetAfterResistanceApplied / interval) * interval
                    }
                   
                    if self.registeredHeaderViews.count > 0 { // If we have a vertical direction, we need to account for landing on a header
                        let stopSection = calendarLayout.sectionFromOffset(finalValue)
                        let heightOfHeader = self.calendarView.layoutAttributesForSupplementaryElementOfKind(UICollectionElementKindSectionHeader, atIndexPath: NSIndexPath(forItem: 0, inSection: stopSection))!.frame.height
                        let heightOfCell = calendarLayout.cellCache[stopSection]![0].frame.height
                        let startOfOffset = stopSection == 0 ? 0 : calendarLayout.sectionSize[stopSection - 1]
                        
                        if finalValue > startOfOffset && finalValue < startOfOffset + heightOfHeader { // If the stop value is on a header
                            if finalValue > (0.50 * heightOfHeader) + startOfOffset {
                                // change the final value to the end of the header
                                finalValue = startOfOffset + heightOfHeader
                            } else {
                                // change the final value to the beginning of the header
                                finalValue = startOfOffset
                            }
                        } else { // If the stop value is on a cell
                            // Check to see if we are to stop at a cell or at a header. If we are then adjust the finalValue
                            if let path = self.calendarView.indexPathForItemAtPoint(CGPoint(x: targetContentOffset.memory.x, y: finalValue)) {
                                let attrib = self.calendarView.layoutAttributesForItemAtIndexPath(path)!
                                finalValue = attrib.frame.origin.y + heightOfCell
                                
                            }
                            if finalValue + scrollView.frame.size.height + heightOfCell >= scrollView.contentSize.height {
                                finalValue -= finalValue + scrollView.frame.size.height - scrollView.contentSize.height
                            }
                        }
                        setTargetContentOffset(finalValue)
                    }
                }
                
            case let .NonStopTo(interval, resistance): // Both horizontal and vertical are fixed
                let diffResistance = diff * resistance
                if isScrollingForward() {
                    let recalcOffsetAfterResistanceApplied = theTargetContentOffset - diffResistance
                    calculatedOffSet = ceil(recalcOffsetAfterResistanceApplied / interval) * interval
                } else if isScrollingBackward() {
                    let recalcOffsetAfterResistanceApplied = theTargetContentOffset + diffResistance
                    calculatedOffSet = floor(recalcOffsetAfterResistanceApplied / interval) * interval
                }

                setTargetContentOffset(calculatedFutureFixedContentOffsetFrom(interval, calculatedOffSet))
            default:
                break
            }
        
        default:
            break
        }
        
        saveLastContentOffset()
        return
    }
    
    /// Tells the delegate when a scrolling animation in the scroll view concludes.
    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if let shouldTrigger = triggerScrollToDateDelegate where shouldTrigger == true {
            scrollViewDidEndDecelerating(scrollView)
            triggerScrollToDateDelegate = nil
        }
        executeDelayedTasks()
        
        // A scroll was just completed.
        scrollInProgress = false
    }
    
    /// Tells the delegate that the scroll view has ended decelerating the scrolling movement.
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let currentSegmentDates = currentCalendarDateSegment()
        self.delegate?.calendar(self, didScrollToDateSegmentStartingWithdate: currentSegmentDates.startDate, endingWithDate: currentSegmentDates.endDate)
    }
}