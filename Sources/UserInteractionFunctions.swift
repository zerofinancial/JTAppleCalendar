//
//  UserInteractionFunctions.swift
//  Pods
//
//  Created by JayT on 2016-05-12.
//
//


extension JTAppleCalendarView {

    /// Returns the cellStatus of a date that is visible on the screen.
    /// If the row and column for the date cannot be found,
    /// then nil is returned
    /// - Paramater row: Int row of the date to find
    /// - Paramater column: Int column of the date to find
    /// - returns:
    ///     - CellState: The state of the found cell
    public func cellStatusForDate(at row: Int, column: Int) -> CellState? {
        guard let section = currentSection() else {
            return nil
        }
        let convertedRow = (row * maxNumberOfDaysInWeek) + column
        let indexPathToFind = IndexPath(item: convertedRow, section: section)
        if let date = dateOwnerInfoFromPath(indexPathToFind) {
            let stateOfCell = cellStateFromIndexPath(indexPathToFind, withDateInfo: date)
            return stateOfCell
        }
        return nil
    }

    /// Returns the cell status for a given date
    /// - Parameter: date Date of the cell you want to find
    /// - returns:
    ///     - CellState: The state of the found cell
    public func cellStatus(for date: Date) -> CellState? {
        // validate the path
        let paths = pathsFromDates([date])
        // Jt101 change this function to also return
        // information like the dateInfoFromPath function
        if paths.isEmpty { return nil }
        let cell = cellForItem(at: paths[0]) as? JTAppleCell
        let stateOfCell = cellStateFromIndexPath(paths[0], cell: cell)
        return stateOfCell
    }
    
    /// Returns the cell status for a given point
    /// - Parameter: point of the cell you want to find
    /// - returns:
    ///     - CellState: The state of the found cell
    public func cellStatus(at point: CGPoint) -> CellState? {
        if let indexPath = indexPathForItem(at: point) {
            let cell = cellForItem(at: indexPath) as? JTAppleCell
            return cellStateFromIndexPath(indexPath, cell: cell)
        }
        return nil
    }
    
    /// Deselect all selected dates
    public func deselectAllDates(triggerSelectionDelegate: Bool = true) {
        deselect(dates: selectedDates, triggerSelectionDelegate: triggerSelectionDelegate)
    }
    
    func deselect(dates: [Date], triggerSelectionDelegate: Bool = true) {
        if allowsMultipleSelection {
            selectDates(dates, triggerSelectionDelegate: triggerSelectionDelegate)
        } else {
            guard let path = pathsFromDates(dates).first else { return }
            collectionView(self, didDeselectItemAt: path)
        }
    }
    
    /// Generates a range of dates from from a startDate to an
    /// endDate you provide
    /// Parameter startDate: Start date to generate dates from
    /// Parameter endDate: End date to generate dates to
    /// returns:
    ///     - An array of the successfully generated dates
    public func generateDateRange(from startDate: Date, to endDate: Date) -> [Date] {
        if startDate > endDate {
            return []
        }
        var returnDates: [Date] = []
        var currentDate = startDate
        repeat {
            returnDates.append(currentDate)
            currentDate = calendar.startOfDay(for: calendar.date(
                byAdding: .day, value: 1, to: currentDate)!)
        } while currentDate <= endDate
        return returnDates
    }

    /// Registers a class for use in creating supplementary views for the collection view.
    public func register(viewClass: AnyClass?, forHeaderViewWithReuseIdentifier identifier: String) {
        register(viewClass, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: identifier)
        updateHeaders(with: identifier, value: viewClass)
    }
    
    public func register(nib: UINib?, forHeaderViewWithReuseIdentifier identifier: String) {
        register(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: identifier)
        updateHeaders(with: identifier, value: nib)
    }
    
    private func updateHeaders(with id: String, value: Any?) {
        layoutNeedsUpdating = true
        guard let value = value else {
            registeredHeaderViews.removeValue(forKey: id)
            return
        }
        registeredHeaderViews.updateValue(value, forKey: id)
    }
    
    
    public func dequeueJTAppleReusableHeader(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> JTAppleCollectionReusableView {
        guard let headerView = dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                             withReuseIdentifier: identifier,
                                                                             for: indexPath) as? JTAppleCollectionReusableView else {
            developerError(string: "Error initializing Header View with identifier: '\(identifier)'")
            return JTAppleCollectionReusableView()
        }
        return headerView
    }
    
    public func dequeueJTAppleReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> JTAppleCell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? JTAppleCell else {
            developerError(string: "Error initializing Cell View with identifier: '\(identifier)'")
            return JTAppleCell()
        }
        
        return cell
    }
    
    /// Reloads the data on the calendar view. Scroll delegates are not
    //  triggered with this function.
    /// - Parameter date: An anchordate that the calendar will
    ///                   scroll to after reload completes
    /// - Parameter animation: Scroll is animated if this is set to true
    /// - Parameter completionHandler: This closure will run after
    ///                                the reload is complete
    public func reloadData(withAnchor date: Date? = nil, animation: Bool = false, completionHandler: (() -> Void)? = nil) {
        if !firstCalendarReloadIsComplete {
            if let validCompletionHandler = completionHandler {
                delayedExecutionClosure.append(validCompletionHandler)
            }
            return
        }
        
        reloadData(checkDelegateDataSource: true,
                   withAnchorDate: date,
                   withAnimation: animation,
                   completionHandler: completionHandler)
    }
    
    /// Reload the date of specified date-cells on the calendar-view
    /// - Parameter dates: Date-cells with these specified
    ///                    dates will be reloaded
    public func reloadDates(_ dates: [Date]) {
        var paths = [IndexPath]()
        for date in dates {
            let aPath = pathsFromDates([date])
            if !aPath.isEmpty && !paths.contains(aPath[0]) {
                paths.append(aPath[0])
                let cellState = cellStateFromIndexPath(aPath[0])
                if let validCounterPartCell =
                    indexPathOfdateCellCounterPart(
                        date,
                        dateOwner: cellState.dateBelongsTo) {
                    paths.append(validCounterPartCell)
                }
            }
        }
        
        // Before reloading, set the proposal path,
        // so that in the event targetContentOffset gets called. We know the path
        setMinVisibleDate()
        
        batchReloadIndexPaths(paths)
    }

    /// Select a date-cell range
    /// - Parameter startDate: Date to start the selection from
    /// - Parameter endDate: Date to end the selection from
    /// - Parameter triggerDidSelectDelegate: Triggers the delegate
    ///   function only if the value is set to true.
    /// Sometimes it is necessary to setup some dates without triggereing
    /// the delegate e.g. For instance, when youre initally setting up data
    /// in your viewDidLoad
    /// - Parameter keepSelectionIfMultiSelectionAllowed: This is only
    ///   applicable in allowedMultiSelection = true.
    /// This overrides the default toggle behavior of selection.
    /// If true, selected cells will remain selected.
    public func selectDates(from startDate: Date, to endDate: Date, triggerSelectionDelegate: Bool = true, keepSelectionIfMultiSelectionAllowed: Bool = false) {
        selectDates(generateDateRange(from: startDate, to: endDate),
                    triggerSelectionDelegate: triggerSelectionDelegate,
                    keepSelectionIfMultiSelectionAllowed: keepSelectionIfMultiSelectionAllowed)
    }
    
    /// Deselect all selected dates within a range
    public func deselectDates(from start: Date, to end: Date? = nil, triggerSelectionDelegate: Bool = true) {
        if selectedDates.isEmpty { return }
        let end = end ?? selectedDates.last!
        let dates = selectedDates.filter { $0 >= start && $0 <= end }
        deselect(dates: dates, triggerSelectionDelegate: triggerSelectionDelegate)
        
    }

    /// Select a date-cells
    /// - Parameter date: The date-cell with this date will be selected
    /// - Parameter triggerDidSelectDelegate: Triggers the delegate function
    ///    only if the value is set to true.
    /// Sometimes it is necessary to setup some dates without triggereing
    /// the delegate e.g. For instance, when youre initally setting up data
    /// in your viewDidLoad
    public func selectDates(_ dates: [Date], triggerSelectionDelegate: Bool = true, keepSelectionIfMultiSelectionAllowed: Bool = false) {
        if !firstCalendarReloadIsComplete {
            // If the calendar is not yet fully loaded.
            // Add the task to the delayed queue
            delayedExecutionClosure.append {[unowned self] in
                self.selectDates(
                    dates,
                    triggerSelectionDelegate: triggerSelectionDelegate,
                    keepSelectionIfMultiSelectionAllowed: keepSelectionIfMultiSelectionAllowed
                )
            }
            return
        }
        var allIndexPathsToReload: [IndexPath] = []
        var validDatesToSelect = dates
        // If user is trying to select multiple dates with
        // multiselection disabled, then only select the last object
        if !allowsMultipleSelection, let dateToSelect = dates.last {
            validDatesToSelect = [dateToSelect]
        }
        let addToIndexSetToReload = { (indexPath: IndexPath) -> Void in
            if !allIndexPathsToReload.contains(indexPath) {
                allIndexPathsToReload.append(indexPath)
            } // To avoid adding the  same indexPath twice.
        }
        
        let selectTheDate = {
            (indexPath: IndexPath, date: Date) -> Void in
            self.selectItem(at: indexPath, animated: false, scrollPosition: [])
            addToIndexSetToReload(indexPath)
            // If triggereing is enabled, then let their delegate
            // handle the reloading of view, else we will reload the data
            if triggerSelectionDelegate {
                self.collectionView(self, didSelectItemAt: indexPath)
            } else {
                // Although we do not want the delegate triggered, we
                // still want counterpart cells to be selected
                // Because there is no triggering of the delegate, the cell
                // will not be added to selection and it will not be
                // reloaded. We need to do this here
                self.addCellToSelectedSetIfUnselected(indexPath, date: date)
                let cellState = self.cellStateFromIndexPath(indexPath)
                // , withDateInfo: date)
                if let aSelectedCounterPartIndexPath = self.selectCounterPartCellIndexPathIfExists(indexPath, date: date, dateOwner: cellState.dateBelongsTo) {
                    // If there was a counterpart cell then
                    // it will also need to be reloaded
                    addToIndexSetToReload(aSelectedCounterPartIndexPath)
                }
            }
        }
        let deSelectTheDate = { (oldIndexPath: IndexPath) -> Void in
            addToIndexSetToReload(oldIndexPath)
            if let index = self.theSelectedIndexPaths
                .index(of: oldIndexPath) {
                let oldDate = self.theSelectedDates[index]
                self.deselectItem(at: oldIndexPath, animated: false)
                self.theSelectedIndexPaths.remove(at: index)
                self.theSelectedDates.remove(at: index)
                // If delegate triggering is enabled, let the
                // delegate function handle the cell
                if triggerSelectionDelegate {
                    self.collectionView(self, didDeselectItemAt: oldIndexPath)
                } else {
                    // Although we do not want the delegate triggered,
                    // we still want counterpart cells to be deselected
                    let cellState = self.cellStateFromIndexPath(oldIndexPath)
                    if let anUnselectedCounterPartIndexPath = self.deselectCounterPartCellIndexPath(oldIndexPath, date: oldDate, dateOwner: cellState.dateBelongsTo) {
                        // If there was a counterpart cell then
                        // it will also need to be reloaded
                        addToIndexSetToReload(anUnselectedCounterPartIndexPath)
                    }
                }
            }
        }
        for date in validDatesToSelect {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            let firstDayOfDate = calendar.date(from: components)!
            // If the date is not within valid boundaries, then exit
            if !(firstDayOfDate >= startOfMonthCache! && firstDayOfDate <= endOfMonthCache!) {
                continue
            }
            let pathFromDates = self.pathsFromDates([date])
            // If the date path youre searching for, doesnt exist, return
            if pathFromDates.isEmpty { continue }
            let sectionIndexPath = pathFromDates[0]
            // Remove old selections
            if self.allowsMultipleSelection == false {
                // If single selection is ON
                let selectedIndexPaths = self.theSelectedIndexPaths
                // made a copy because the array is about to be mutated
                for indexPath in selectedIndexPaths {
                    if indexPath != sectionIndexPath {
                        deSelectTheDate(indexPath)
                    }
                }
                // Add new selections
                // Must be added here. If added in delegate
                // didSelectItemAtIndexPath
                selectTheDate(sectionIndexPath, date)
            } else {
                // If multiple selection is on. Multiple selection behaves
                // differently to singleselection.
                // It behaves like a toggle. unless
                // keepSelectionIfMultiSelectionAllowed is true.
                // If user wants to force selection if multiselection
                // is enabled, then removed the selected dates from
                // generated dates
                if keepSelectionIfMultiSelectionAllowed {
                    if selectedDates.contains(calendar.startOfDay(for: date)) {
                        addToIndexSetToReload(sectionIndexPath)
                        continue
                        // Do not deselect or select the cell.
                        // Just add it to be reloaded
                    }
                }
                if self.theSelectedIndexPaths.contains(sectionIndexPath) {
                    // If this cell is already selected, then deselect it
                    deSelectTheDate(sectionIndexPath)
                } else {
                    // Add new selections
                    // Must be added here. If added in delegate
                    // didSelectItemAtIndexPath
                    selectTheDate(sectionIndexPath, date)
                }
            }
        }
        // If triggering was false, although the selectDelegates weren't
        // called, we do want the cell refreshed.
        // Reload to call itemAtIndexPath
        if !triggerSelectionDelegate && !allIndexPathsToReload.isEmpty {
            self.batchReloadIndexPaths(allIndexPathsToReload)
        }
    }
    
    /// Scrolls the calendar view to the next section view. It will execute a completion handler at the end of scroll animation if provided.
    /// - Paramater direction: Indicates a direction to scroll
    /// - Paramater animateScroll: Bool indicating if animation should be enabled
    /// - Parameter triggerScrollToDateDelegate: trigger delegate if set to true
    /// - Parameter completionHandler: A completion handler that will be executed at the end of the scroll animation
    public func scrollToSegment(_ destination: SegmentDestination, triggerScrollToDateDelegate: Bool = true, animateScroll: Bool = true, completionHandler: (() -> Void)? = nil) {
        if !firstCalendarReloadIsComplete {
            delayedExecutionClosure.append {[unowned self] in
                self.scrollToSegment(destination, triggerScrollToDateDelegate: triggerScrollToDateDelegate, animateScroll: animateScroll, completionHandler: completionHandler)
            }
        }
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0
        
        let fixedScrollSize: CGFloat
        if scrollDirection == .horizontal {
            if thereAreHeaders || cachedConfiguration.generateOutDates == .tillEndOfGrid {
                fixedScrollSize = calendarViewLayout.sizeOfContentForSection(0)
            } else {
                fixedScrollSize = frame.width
            }
            let section = CGFloat(Int(contentOffset.x / fixedScrollSize))
            xOffset = (fixedScrollSize * section)
            switch destination {
            case .next:
                xOffset += fixedScrollSize
            case .previous:
                xOffset -= fixedScrollSize
            case .end:
                xOffset = contentSize.width - frame.width
            case .start:
                xOffset = 0
            }
            
            if xOffset <= 0 {
                xOffset = 0
            } else if xOffset >= contentSize.width - frame.width {
                xOffset = contentSize.width - frame.width
            }
        } else {
            if thereAreHeaders {
                guard let section = currentSection() else {
                    return
                }
                if (destination == .next && section + 1 >= numberOfSections(in: self)) ||
                    destination == .previous && section - 1 < 0 ||
                    numberOfSections(in: self) < 0 {
                    return
                }
                
                switch destination {
                case .next:
                    scrollToHeaderInSection(section + 1)
                case .previous:
                    scrollToHeaderInSection(section - 1)
                case .start:
                    scrollToHeaderInSection(0)
                case .end:
                    scrollToHeaderInSection(numberOfSections(in: self) - 1)
                }
                return
            } else {
                fixedScrollSize = frame.height
                let section = CGFloat(Int(contentOffset.y / fixedScrollSize))
                yOffset = (fixedScrollSize * section) + fixedScrollSize
            }
            
            if yOffset <= 0 {
                yOffset = 0
            } else if yOffset >= contentSize.height - frame.height {
                yOffset = contentSize.height - frame.height
            }
        }
        
        let rect = CGRect(x: xOffset, y: yOffset, width: frame.width, height: frame.height)
        scrollTo(rect: rect, triggerScrollToDateDelegate: triggerScrollToDateDelegate, isAnimationEnabled: true, completionHandler: completionHandler)
    }

    /// Scrolls the calendar view to the start of a section view containing a specified date.
    /// - Paramater date: The calendar view will scroll to a date-cell containing this date if it exists
    /// - Parameter triggerScrollToDateDelegate: Trigger delegate if set to true
    /// - Paramater animateScroll: Bool indicating if animation should be enabled
    /// - Paramater preferredScrollPositionIndex: Integer indicating the end scroll position on the screen.
    /// This value indicates column number for Horizontal scrolling and row number for a vertical scrolling calendar
    /// - Parameter completionHandler: A completion handler that will be executed at the end of the scroll animation
    public func scrollToDate(_ date: Date,
                             triggerScrollToDateDelegate: Bool = true,
                             animateScroll: Bool = true,
                             preferredScrollPosition: UICollectionViewScrollPosition? = nil,
                             completionHandler: (() -> Void)? = nil) {
        if !firstCalendarReloadIsComplete {
            delayedExecutionClosure.append {[unowned self] in
                self.scrollToDate(date,
                                  triggerScrollToDateDelegate: triggerScrollToDateDelegate,
                                  animateScroll: animateScroll,
                                  preferredScrollPosition: preferredScrollPosition,
                                  completionHandler: completionHandler)
            }
            return
        }
        self.triggerScrollToDateDelegate = triggerScrollToDateDelegate
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let firstDayOfDate = calendar.date(from: components)!
        
        func handleScroll(point: CGPoint? = nil,
                          indexPath: IndexPath? = nil,
                          triggerScrollToDateDelegate: Bool = true,
                          isAnimationEnabled: Bool,
                          position: UICollectionViewScrollPosition? = .left,
                          completionHandler: (() -> Void)?) {
            
            if scrollInProgress {
                return
            }
            
            // Rect takes preference
            if let validPoint = point {
                scrollInProgress = true
                scrollTo(point: validPoint, triggerScrollToDateDelegate: triggerScrollToDateDelegate, isAnimationEnabled: isAnimationEnabled, completionHandler: completionHandler)
            } else {
                guard let validIndexPath = indexPath else {
                    return
                }
                
                if thereAreHeaders && scrollDirection == .vertical {
                    scrollToHeaderInSection(validIndexPath.section,
                                            triggerScrollToDateDelegate: triggerScrollToDateDelegate,
                                            withAnimation: isAnimationEnabled,
                                            completionHandler: completionHandler)
                    return
                } else {
                    let validPosition = position ?? .left
                    scrollInProgress = true
                    self.scrollTo(indexPath: validIndexPath, isAnimationEnabled: isAnimationEnabled, position: validPosition, completionHandler: completionHandler)
                }
            }
            
            // Jt101 put this into a function to reduce code between
            // this and the scroll to header function
            if !isAnimationEnabled {
                self.scrollViewDidEndScrollingAnimation(self)
            }
            self.scrollInProgress = false
        }
        
        // This part should be inside the mainRunLoop
        if !((firstDayOfDate >= self.startOfMonthCache!) && (firstDayOfDate <= self.endOfMonthCache!)) {
            return
        }
        let retrievedPathsFromDates = self.pathsFromDates([date])
        guard !retrievedPathsFromDates.isEmpty else { return }
        let sectionIndexPath =  self.pathsFromDates([date])[0]
        var position: UICollectionViewScrollPosition = self.scrollDirection == .horizontal ? .left : .top
        if !self.scrollingMode.pagingIsEnabled() {
            if let validPosition = preferredScrollPosition {
                if self.scrollDirection == .horizontal {
                    if validPosition == .left || validPosition == .right || validPosition == .centeredHorizontally {
                        position = validPosition
                    }
                } else {
                    if validPosition == .top || validPosition == .bottom || validPosition == .centeredVertically {
                        position = validPosition
                    }
                }
            }
        }
        var point: CGPoint?
        switch self.scrollingMode {
        case .stopAtEach, .stopAtEachSection, .stopAtEachCalendarFrameWidth:
            if self.scrollDirection == .horizontal || (self.scrollDirection == .vertical && !self.thereAreHeaders) {
                point = self.targetPointForItemAt(indexPath: sectionIndexPath)
            }
        default:
            break
        }
        handleScroll(point: point,
                     indexPath: sectionIndexPath,
                     triggerScrollToDateDelegate: triggerScrollToDateDelegate,
                     isAnimationEnabled: animateScroll,
                     position: position,
                     completionHandler: completionHandler)
    }
    
    func scrollTo(point: CGPoint, triggerScrollToDateDelegate: Bool? = nil, isAnimationEnabled: Bool, completionHandler: (() -> Void)?) {
        if let validCompletionHandler = completionHandler {
            self.delayedExecutionClosure.append(validCompletionHandler)
        }
        self.triggerScrollToDateDelegate = triggerScrollToDateDelegate
        scrollInProgress = true
        setContentOffset(point, animated: isAnimationEnabled)
        scrollInProgress = false
    }
    
    func scrollTo(rect: CGRect, triggerScrollToDateDelegate: Bool? = nil, isAnimationEnabled: Bool, completionHandler: (() -> Void)?) {
        scrollTo(point: CGPoint(x: rect.origin.x, y: rect.origin.y), triggerScrollToDateDelegate: triggerScrollToDateDelegate, isAnimationEnabled: isAnimationEnabled, completionHandler: completionHandler)
    }
    
    /// Scrolls the calendar view to the start of a section view header.
    /// If the calendar has no headers registered, then this function does nothing
    /// - Paramater date: The calendar view will scroll to the header of
    /// a this provided date
    public func scrollToHeaderForDate(_ date: Date, triggerScrollToDateDelegate: Bool = false, withAnimation animation: Bool = false, completionHandler: (() -> Void)? = nil) {
        let path = pathsFromDates([date])
        // Return if date was incalid and no path was returned
        if path.isEmpty { return }
        scrollToHeaderInSection(
            path[0].section,
            triggerScrollToDateDelegate: triggerScrollToDateDelegate,
            withAnimation: animation,
            completionHandler: completionHandler
        )
    }
    
    /// Returns the visible dates of the calendar.
    /// - returns:
    ///     - DateSegmentInfo
    public func visibleDates()-> DateSegmentInfo {
        let emptySegment = DateSegmentInfo(indates: [], monthDates: [], outdates: [], indateIndexes: [], monthDateIndexes: [], outdateIndexes: [])
        
        if !firstCalendarReloadIsComplete {
            return emptySegment
        }
        
        let cellAttributes = visibleElements(excludeHeaders: true)
        let indexPaths: [IndexPath] = cellAttributes.map { $0.indexPath }.sorted()
        return dateSegmentInfoFrom(visible: indexPaths)
    }
    /// Returns the visible dates of the calendar.
    /// - returns:
    ///     - DateSegmentInfo
    public func visibleDates(_ completionHandler: @escaping (_ dateSegmentInfo: DateSegmentInfo) ->()) {
        if !firstCalendarReloadIsComplete {
            delayedExecutionClosure.append {[unowned self] in
                self.visibleDates(completionHandler)
            }
            return
        }
        let retval = visibleDates()
        completionHandler(retval)
    }
}
