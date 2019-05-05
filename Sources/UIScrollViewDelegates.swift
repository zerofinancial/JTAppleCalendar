//
//  UIScrollViewDelegates.swift
//
//  Copyright (c) 2016-2017 JTAppleCalendar (https://github.com/patchthecode/JTAppleCalendar)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
extension JTAppleCalendarView: UIScrollViewDelegate {
    /// Inform the scrollViewDidEndDecelerating
    /// function that scrolling just occurred
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollViewDidEndDecelerating(self)
    }

    public func saveLastContentOffset(_ offset: CGPoint) {
        lastSavedContentOffset = scrollDirection == .horizontal ? offset.x : offset.y
    }

    /// Tells the delegate when the user finishes scrolling the content.
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let theCurrentSection = currentSection() else { return }
        
        let maxContentOffset: CGFloat
        var contentOffset: CGFloat = 0,
        theTargetContentOffset: CGFloat = 0,
        directionVelocity: CGFloat = 0
        let calendarLayout = calendarViewLayout
        if scrollDirection == .horizontal {
            contentOffset = scrollView.contentOffset.x
            theTargetContentOffset = targetContentOffset.pointee.x
            directionVelocity = velocity.x
            maxContentOffset = scrollView.contentSize.width - scrollView.frame.width
        } else {
            contentOffset = scrollView.contentOffset.y
            theTargetContentOffset = targetContentOffset.pointee.y
            directionVelocity = velocity.y
            maxContentOffset = scrollView.contentSize.height - scrollView.frame.height
        }
        
        // If no scrolling is occuring
        if contentOffset == lastSavedContentOffset {
            return
        }
        
        
        let setTargetContentOffset = {(finalOffset: CGFloat) -> Void in
            if self.scrollDirection == .horizontal {
                targetContentOffset.pointee.x = finalOffset
            } else {
                targetContentOffset.pointee.y = finalOffset
            }
            self.endScrollTargetLocation = finalOffset
        }
        
        if didEndScollCount > 0, directionVelocity == 0, scrollingMode != .none {
            setTargetContentOffset(endScrollTargetLocation)
            return
        }
        
        didEndScollCount += 1
        
        if directionVelocity == 0.0 {
            decelerationRate = .fast
        }
        
        
        let isScrollingForward = {
            return directionVelocity > 0 ||  contentOffset > self.lastSavedContentOffset
        }
        
        let calculatedCurrentFixedContentOffsetFrom = {(interval: CGFloat) -> CGFloat in
            if isScrollingForward() {
                return ceil(contentOffset / interval) * interval
            } else {
                return floor(contentOffset / interval) * interval
            }
        }
        
        let recalculateOffset = {(diff: CGFloat, interval: CGFloat) -> CGFloat in
            if isScrollingForward() {
                let recalcOffsetAfterResistanceApplied = theTargetContentOffset - diff
                return ceil(recalcOffsetAfterResistanceApplied / interval) * interval
            } else {
                let recalcOffsetAfterResistanceApplied = theTargetContentOffset + diff
                return floor(recalcOffsetAfterResistanceApplied / interval) * interval
            }
        }
        

        switch scrollingMode {
        case let .stopAtEach(customInterval: interval):
            let calculatedOffset = calculatedCurrentFixedContentOffsetFrom(interval)
            setTargetContentOffset(calculatedOffset)
        case .stopAtEachCalendarFrame:
            #if os(tvOS)
                let interval = scrollDirection == .horizontal ? scrollView.frame.width : scrollView.frame.height
                let calculatedOffset = calculatedCurrentFixedContentOffsetFrom(interval)
                setTargetContentOffset(calculatedOffset)
            #else
                setTargetContentOffset(scrollDirection == .horizontal ? targetContentOffset.pointee.x : targetContentOffset.pointee.y)
            #endif
            break
        case .stopAtEachSection:
            var calculatedOffSet: CGFloat = 0
            if scrollDirection == .horizontal {
                // Horizontal has a fixed width.
                let interval = calendarLayout.sizeOfContentForSection(theCurrentSection)
                calculatedOffSet = calculatedCurrentFixedContentOffsetFrom(interval)
            } else {
                // Vertical have variable heights. It needs to be calculated
                let currentScrollOffset = scrollView.contentOffset.y
                let currentScrollSection = calendarLayout.sectionFromOffset(currentScrollOffset)
                var sectionSize: CGFloat = 0
                if isScrollingForward() {
                    sectionSize = calendarLayout.sectionSize[currentScrollSection]
                    calculatedOffSet = sectionSize
                } else {
                    if currentScrollSection - 1  >= 0 {
                        calculatedOffSet = calendarLayout.sectionSize[currentScrollSection - 1]
                    }
                }
            }
            setTargetContentOffset(calculatedOffSet)
        case let .nonStopToCell(withResistance: resistance):
            let diff = abs(theTargetContentOffset - contentOffset)
            var calculatedOffSet: CGFloat = 0
            let targetSection = calendarLayout.sectionFromOffset(theTargetContentOffset)
            let diffResistance = diff * resistance


                let interval = scrollDirection == .horizontal ? calendarLayout.cellCache[targetSection]![0].width : calendarLayout.cellCache[targetSection]![0].height
                print("interval: \(interval)")
                let recalculateOffset = {(diff: CGFloat, interval: CGFloat) -> CGFloat in
                    if contentOffset >= maxContentOffset { return maxContentOffset }
                    if contentOffset <= 0 { return 0 }
                    
                    
                    let gestureTranslation = self.panGestureRecognizer.translation(in: self)
                    let translation = self.scrollDirection == .horizontal ? gestureTranslation.x : gestureTranslation.y
                    
                    
                    let recalcOffsetAfterResistanceApplied = translation > 0 ? theTargetContentOffset + diff : theTargetContentOffset - diff
                    
                    
                    
                    print("recalcOffsetAfterResistanceApplied: \(recalcOffsetAfterResistanceApplied)")
                    let rect = self.scrollDirection == .horizontal ?
                        CGRect(x: recalcOffsetAfterResistanceApplied + 1, y: self.contentOffset.y + 1, width: self.frame.width - 2, height: self.frame.height - 2) :
                        CGRect(x: self.contentOffset.x + 1, y: recalcOffsetAfterResistanceApplied + 1, width: self.frame.width - 2, height: self.frame.height - 2)
                    
                    let element = calendarLayout.elementsAtRect(excludeHeaders: true, from: rect).map { $0.indexPath }.sorted().first!
                    let ele = calendarLayout.cachedValue(for: element.item, section: element.section)
                    print("ele: \(ele!)\n")
                    let midPoint = self.scrollDirection == .horizontal ? (ele!.xOffset + ( ele!.xOffset + ele!.width)) / 2 : (ele!.yOffset + ( ele!.yOffset + ele!.height)) / 2
                    if recalcOffsetAfterResistanceApplied > midPoint || theTargetContentOffset >= maxContentOffset {
                        return self.scrollDirection == .horizontal ? ele!.xOffset + ele!.width : ele!.yOffset + ele!.height
                    } else {
                        return self.scrollDirection == .horizontal ? ele!.xOffset : ele!.yOffset
                    }
                    
                }
                calculatedOffSet = recalculateOffset(diffResistance, interval)
        
            setTargetContentOffset(calculatedOffSet)
        case .nonStopToSection, .nonStopTo:
            let diff = abs(theTargetContentOffset - contentOffset)
            let targetSection = calendarLayout.sectionFromOffset(theTargetContentOffset)
            var calculatedOffSet = contentOffset
            switch scrollingMode {
            case let .nonStopToSection(resistance):
                let interval = calendarLayout.sizeOfContentForSection(targetSection)
                let diffResistance = diff * resistance
                if scrollDirection == .horizontal {
                    calculatedOffSet = recalculateOffset(diffResistance, interval)
                } else {
                    if isScrollingForward() {
                        calculatedOffSet = theTargetContentOffset - diffResistance
                    } else {
                        calculatedOffSet = theTargetContentOffset + diffResistance
                    }
                    let stopSection = isScrollingForward() ?
                        calendarLayout.sectionFromOffset(calculatedOffSet) :
                        calendarLayout.sectionFromOffset(calculatedOffSet) - 1
                    calculatedOffSet = stopSection < 0 ?
                        0 : calendarLayout.sectionSize[stopSection]
                }
                setTargetContentOffset(calculatedOffSet)
            case .nonStopToCell(_): break // fixed above
            case let .nonStopTo(interval, resistance):
                // Both horizontal and vertical are fixed
                let diffResistance = diff * resistance
                calculatedOffSet =
                    recalculateOffset(diffResistance, interval)
                setTargetContentOffset(calculatedOffSet)
            default:
                break
            }
        case .none: break
        }
        
        let futureScrollPoint = CGPoint(x: targetContentOffset.pointee.x, y: targetContentOffset.pointee.y)
        saveLastContentOffset(futureScrollPoint)
        let dateSegmentInfo = datesAtCurrentOffset(futureScrollPoint)
        calendarDelegate?.calendar(self, willScrollToDateSegmentWith: dateSegmentInfo)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            self.decelerationRate = UIScrollView.DecelerationRate(rawValue: self.decelerationRateMatchingScrollingMode)
        }
        
        DispatchQueue.main.async {
            self.calendarDelegate?.scrollDidEndDecelerating(for: self)
        }
    }
    
    /// Tells the delegate when a scrolling
    /// animation in the scroll view concludes.
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrollInProgress = false
        if
            let shouldTrigger = triggerScrollToDateDelegate,
            shouldTrigger == true {
            scrollViewDidEndDecelerating(scrollView)
            triggerScrollToDateDelegate = nil
        }
        
        DispatchQueue.main.async { // https://github.com/patchthecode/JTAppleCalendar/issues/778
            self.executeDelayedTasks(.scroll)
            self.saveLastContentOffset(scrollView.contentOffset)
        }
    }
    
    /// Tells the delegate that the scroll view has
    /// ended decelerating the scrolling movement.
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didEndScollCount = 0
        visibleDates {[unowned self] dates in
            self.calendarDelegate?.calendar(self, didScrollToDateSegmentWith: dates)
        }
    }
    
    /// Tells the delegate that a scroll occured
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        calendarDelegate?.calendarDidScroll(self)
    }
}
