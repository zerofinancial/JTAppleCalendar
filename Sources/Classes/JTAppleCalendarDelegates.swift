//
//  JTAppleCalendarDelegates.swift
//  Pods
//
//  Created by Jay Thomas on 2016-05-12.
//
//
var xOffset: CGFloat = 0

// MARK: CollectionView delegates
extension JTAppleCalendarView: UICollectionViewDataSource, UICollectionViewDelegate {
    /// Asks your data source object to provide a supplementary view to display in the collection view.
    
    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        guard let date = dateFromSection(indexPath.section) else {
            assert(false, "Date could not be generated fro section. This is a bug. Contact the developer")
            return UICollectionReusableView()
        }
        
        let reuseIdentifier: String
        var source: JTAppleCalendarViewSource = registeredHeaderViews[0]
        
        // Get the reuse identifier and index
        if registeredHeaderViews.count == 1 {
            switch registeredHeaderViews[0] {
            case let .fromXib(xibName): reuseIdentifier = xibName
            case let .fromClassName(className): reuseIdentifier = className
            case let .fromType(classType): reuseIdentifier = classType.description()
            }
        } else {
            reuseIdentifier = delegate!.calendar(self, sectionHeaderIdentifierForDate: date)!
            for item in registeredHeaderViews {
                switch item {
                case let .fromXib(xibName) where xibName == reuseIdentifier:
                    source = item
                    break
                case let .fromClassName(className) where className == reuseIdentifier:
                    source = item
                    break
                case let .fromType(type) where type.description() == reuseIdentifier:
                    source = item
                    break
                default:
                    continue
                }
            }
        }
        
        let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: reuseIdentifier, forIndexPath: indexPath) as! JTAppleCollectionReusableView
        headerView.setupView(source)
        headerView.update()
        delegate?.calendar(self, isAboutToDisplaySectionHeader: headerView.view!, date: date, identifier: reuseIdentifier)
        return headerView
    }
    
    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        delegate?.calendar(self, isAboutToResetCell: (cell as! JTAppleDayCell).view!)
    }
    
    /// Asks your data source object for the cell that corresponds to the specified item in the collection view.
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        restoreSelectionStateForCellAtIndexPath(indexPath)
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! JTAppleDayCell
        
        cell.setupView(cellViewSource)
        cell.updateCellView(cellInset.x, cellInsetY: cellInset.y)
        cell.bounds.origin = CGPoint(x: 0, y: 0)
        
        let date = dateFromPath(indexPath)!
        let cellState = cellStateFromIndexPath(indexPath, withDate: date)
        
        delegate?.calendar(self, isAboutToDisplayCell: cell.view!, date: date, cellState: cellState)

        return cell
    }
    /// Asks your data source object for the number of sections in the collection view. The number of sections in collectionView.
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return monthInfo.count
    }

    /// Asks your data source object for the number of items in the specified section. The number of rows in section.
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  MAX_NUMBER_OF_DAYS_IN_WEEK * cachedConfiguration.numberOfRows
    }
    /// Asks the delegate if the specified item should be selected. true if the item should be selected or false if it should not.
    public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        
        if let
            delegate = self.delegate,
            dateUserSelected = dateFromPath(indexPath),
            cell = collectionView.cellForItemAtIndexPath(indexPath) as? JTAppleDayCell
        where
            cellWasNotDisabledOrHiddenByTheUser(cell) {
            let cellState = cellStateFromIndexPath(indexPath, withDate: dateUserSelected)
            return delegate.calendar(self, canSelectDate: dateUserSelected, cell: cell.view!, cellState: cellState)
        }
        return false
    }
    
    func cellWasNotDisabledOrHiddenByTheUser(cell: JTAppleDayCell) -> Bool {
        return cell.view!.hidden == false && cell.view!.userInteractionEnabled == true
    }
    
    /// Tells the delegate that the item at the specified path was deselected. The collection view calls this method when the user successfully deselects an item in the collection view. It does not call this method when you programmatically deselect items.
    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        internalCollectionView(collectionView, didDeselectItemAtIndexPath: indexPath, indexPathsToReload: theSelectedIndexPaths)
    }
    func internalCollectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath, indexPathsToReload: [NSIndexPath] = []) {
        if let
            delegate = self.delegate,
            dateDeselectedByUser = dateFromPath(indexPath) {
            
            // Update model
            deleteCellFromSelectedSetIfSelected(indexPath)
            
            let selectedCell = collectionView.cellForItemAtIndexPath(indexPath) as? JTAppleDayCell // Cell may be nil if user switches month sections
            let cellState = cellStateFromIndexPath(indexPath, withDate: dateDeselectedByUser, cell: selectedCell) // Although the cell may be nil, we still want to return the cellstate
            var pathsToReload = indexPathsToReload
            if let anUnselectedCounterPartIndexPath = deselectCounterPartCellIndexPath(indexPath, date: dateDeselectedByUser, dateOwner: cellState.dateBelongsTo) {
                deleteCellFromSelectedSetIfSelected(anUnselectedCounterPartIndexPath)
                // ONLY if the counterPart cell is visible, then we need to inform the delegate
                if !pathsToReload.contains(anUnselectedCounterPartIndexPath){ pathsToReload.append(anUnselectedCounterPartIndexPath) }
            }
            if pathsToReload.count > 0 {
                delayRunOnMainThread(0.0) {
                    self.batchReloadIndexPaths(pathsToReload)
                }
            }
            delegate.calendar(self, didDeselectDate: dateDeselectedByUser, cell: selectedCell?.view, cellState: cellState)
        }
    }
    
    /// Asks the delegate if the specified item should be deselected. true if the item should be deselected or false if it should not.
    public func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let
            delegate = self.delegate,
            dateDeSelectedByUser = dateFromPath(indexPath),
            cell = collectionView.cellForItemAtIndexPath(indexPath) as? JTAppleDayCell
        where cellWasNotDisabledOrHiddenByTheUser(cell) {
            let cellState = cellStateFromIndexPath(indexPath, withDate: dateDeSelectedByUser)
            return delegate.calendar(self, canDeselectDate: dateDeSelectedByUser, cell: cell.view!, cellState:  cellState)
        }
        return false
    }
    
    /// Tells the delegate that the item at the specified index path was selected. The collection view calls this method when the user successfully selects an item in the collection view. It does not call this method when you programmatically set the selection.
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        internalCollectionView(collectionView, didSelectItemAtIndexPath: indexPath, indexPathsToReload: theSelectedIndexPaths)
    }
    
    func internalCollectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath, indexPathsToReload: [NSIndexPath] = []) {
        if let
            delegate = self.delegate,
            dateSelectedByUser = dateFromPath(indexPath) {
            
            // Update model
            addCellToSelectedSetIfUnselected(indexPath, date:dateSelectedByUser)
            let selectedCell = collectionView.cellForItemAtIndexPath(indexPath) as? JTAppleDayCell
            
            // If cell has a counterpart cell, then select it as well
            let cellState = cellStateFromIndexPath(indexPath, withDate: dateSelectedByUser, cell: selectedCell)
            var pathsToReload = indexPathsToReload
            if let aSelectedCounterPartIndexPath = selectCounterPartCellIndexPathIfExists(indexPath, date: dateSelectedByUser, dateOwner: cellState.dateBelongsTo) {
                // ONLY if the counterPart cell is visible, then we need to inform the delegate
                if !pathsToReload.contains(aSelectedCounterPartIndexPath){ pathsToReload.append(aSelectedCounterPartIndexPath) }
            }
            if pathsToReload.count > 0 {
                delayRunOnMainThread(0.0) {
                    self.batchReloadIndexPaths(pathsToReload)
                }
            }
            
            delegate.calendar(self, didSelectDate: dateSelectedByUser, cell: selectedCell?.view, cellState: cellState)
        }
    }
}
