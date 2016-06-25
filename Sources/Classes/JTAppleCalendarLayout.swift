//
//  JTAppleCalendarLayout.swift
//  JTAppleCalendar
//
//  Created by Jay Thomas on 2016-03-01.
//  Copyright © 2016 OS-Tech. All rights reserved.
//


/// Base class for the Horizontal layout
public class JTAppleCalendarLayout: UICollectionViewLayout, JTAppleCalendarLayoutProtocol {
    var itemSize: CGSize = CGSizeZero
    var headerReferenceSize: CGSize = CGSizeZero
    var scrollDirection: UICollectionViewScrollDirection = .Horizontal
    var maxSections: Int = 0
    var daysPerSection: Int = 0
    
    var numberOfColumns: Int { get { return delegate!.numberOfColumns() } }
    var numberOfMonthsInCalendar: Int { get { return delegate!.numberOfMonthsInCalendar() } }
    var numberOfSectionsPerMonth: Int { get { return delegate!.numberOfsectionsPermonth() } }
    var numberOfDaysPerSection: Int { get { return delegate!.numberOfDaysPerSection() } }
    var numberOfRows: Int { get { return delegate!.numberOfRows() } }
    
    var cellCache: [Int:[UICollectionViewLayoutAttributes]] = [:]
    var headerCache: [UICollectionViewLayoutAttributes] = []
    
    weak var delegate: JTAppleCalendarDelegateProtocol?
    
    var currentHeader: (section: Int, size: CGSize)? // Tracks the current header size
    var currentCell: (section: Int, itemSize: CGSize)? // Tracks the current cell size
    
    var contentHeight: CGFloat = 0 // Content height of calendarView
    var contentWidth: CGFloat = 0 // Content wifth of calendarView
    
    init(withDelegate delegate: JTAppleCalendarDelegateProtocol) {
        super.init()
        self.delegate = delegate
    }
    
    /// Tells the layout object to update the current layout.
    public override func prepareLayout() {
        if !cellCache.isEmpty { return }
        
        maxSections = numberOfMonthsInCalendar * numberOfSectionsPerMonth
        daysPerSection = numberOfDaysPerSection
        
         // Generate and cache the headers
        for section in 0..<maxSections {
            if headerViewXibs.count > 0 {
                // generate header views
                let sectionIndexPath = NSIndexPath(forItem: 0, inSection: section)
                if let aHeaderAttr = layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: sectionIndexPath) {
                    headerCache.append(aHeaderAttr)
                    if scrollDirection == .Vertical { contentHeight += aHeaderAttr.frame.height } else { contentWidth += aHeaderAttr.frame.width }
                }
            }
            
            // Generate and cache the cells
            for item in 0..<daysPerSection {
                let indexPath = NSIndexPath(forItem: item, inSection: section)
                if let attribute = layoutAttributesForItemAtIndexPath(indexPath) {
                    if cellCache[section] == nil {
                        cellCache[section] = []
                        
                        if scrollDirection == .Vertical {
                            contentHeight += (attribute.frame.height * CGFloat(numberOfRows))
                        } else {
                            contentWidth += (attribute.frame.width * CGFloat(numberOfColumns))
                        }
                    }
                    cellCache[section]!.append(attribute)
                }
            }

        }
        
        if scrollDirection == .Horizontal {
//            contentWidth = self.collectionView!.bounds.size.width * CGFloat(numberOfMonthsInCalendar * numberOfSectionsPerMonth)
            contentHeight = self.collectionView!.bounds.size.height
        } else {
            contentWidth = self.collectionView!.bounds.size.width
        }
    }
    
    /// Returns the width and height of the collection view’s contents. The width and height of the collection view’s contents.
    public override func collectionViewContentSize() -> CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    /// Returns the layout attributes for all of the cells and views in the specified rectangle.
    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var startSectionIndex = scrollDirection == .Horizontal ? Int(floor(rect.origin.x / collectionView!.frame.width)): Int(floor(rect.origin.y / collectionView!.frame.height))
        if startSectionIndex < 0 { startSectionIndex = 0 }
        if startSectionIndex > cellCache.count { startSectionIndex = cellCache.count }
        
        // keep looping until there were no interception rects
        var attributes: [UICollectionViewLayoutAttributes] = []
        let maxMissCount = scrollDirection == .Horizontal ? 6 : 7
        for sectionIndex in startSectionIndex..<cellCache.count {
            if let validSection = cellCache[sectionIndex] where validSection.count > 0 {
                
                // Add header view attributes
                var interceptCount: Int  = 0
                if headerViewXibs.count > 0 {
                    interceptCount += 1
                    if CGRectIntersectsRect(headerCache[sectionIndex].frame, rect) {
                        attributes.append(headerCache[sectionIndex])
                    }
                }
                
                var missCount = 0
                var beganIntercepting = false
                for val in validSection {
                    if CGRectIntersectsRect(val.frame, rect) {
                        missCount = 0
                        beganIntercepting = true
                        attributes.append(val)
                    } else {
                        missCount += 1
                        if missCount > maxMissCount && beganIntercepting { // If there are at least 8 misses in a row since intercepting began, then this section has no more interceptions. So break
                            break
                        }
                    }
                }
                if missCount > maxMissCount && beganIntercepting { // Also break from outter loop
                    break
                }
            }
        }
        return attributes
    }
    
    /// Returns the layout attributes for the item at the specified index path. A layout attributes object containing the information to apply to the item’s cell.
    override  public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
        
        // If this index is already cached, then return it else, apply a new layout attribut to it
        if let alreadyCachedCellAttrib = cellCache[indexPath.section] where indexPath.item < alreadyCachedCellAttrib.count {
            return alreadyCachedCellAttrib[indexPath.item]
        }
        
        applyLayoutAttributes(attr)
        return attr
    }
    
    /// Returns the layout attributes for the specified supplementary view.
    public override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
        
        // We cache the header here so we dont call the delegate so much
        let headerSize = cachedHeaderSizeForSection(indexPath.section)
//        print("CH = \(headerSize)")
        
        var strideOffset: CGFloat = 0
        if indexPath.section > 0 {
            let headerHeightOfPreviousSection = headerCache[attributes.indexPath.section - 1].frame.height
//            print("PH = \(headerSize)")
            let itemSectionSizeOfPreviousSection = cellCache[attributes.indexPath.section - 1]![0].frame.height * CGFloat(numberOfRows)
            let heightStride = itemSectionSizeOfPreviousSection + headerHeightOfPreviousSection + headerCache[attributes.indexPath.section - 1].frame.origin.y
            
            strideOffset = scrollDirection == .Horizontal ?
                itemSize.width * CGFloat(numberOfColumns) :
                heightStride
        }
        
        // Use the calculaed header size and force thw width of the header to take up 7 columns
        let modifiedSize = CGSize(width: itemSize.width * CGFloat(numberOfColumns), height: headerSize.height)
        
        
        
        attributes.frame = scrollDirection == .Horizontal ?
            CGRect(x: strideOffset, y: 0, width: modifiedSize.width, height: modifiedSize.height) :
            CGRect(x: 0, y: strideOffset, width: modifiedSize.width, height: modifiedSize.height)
        if attributes.frame == CGRectZero { return nil }
        
        return attributes
    }
    
    func applyLayoutAttributes(attributes : UICollectionViewLayoutAttributes) {
        if attributes.representedElementKind != nil { return }
        guard let collectionView = self.collectionView else { return }
    
        
        if let itemSize = delegate!.itemSize {
            if scrollDirection == .Vertical { self.itemSize.height = itemSize } else { self.itemSize.width = itemSize}
        } else {
            let sizeOfItem = sizeForitemAtIndexPath(attributes.indexPath)
            itemSize.height = sizeOfItem.height
            // jt101 the width is already set form the outside. may change this to all inside here.
        }
        
        var stride: CGFloat = 0
        
        // If we have headers the cell must start under the header
        if headerViewXibs.count > 0 {
            let headerSize = headerCache[attributes.indexPath.section].frame.height
            let headerOrigin = headerCache[attributes.indexPath.section].frame.origin.y
            stride += headerSize + headerOrigin
        } else { // If there are no headers then alll the cells will have the same height, therefore the strides will have the same height
            
            stride = scrollDirection == .Horizontal ?
                 CGFloat(attributes.indexPath.section) * itemSize.width * CGFloat(numberOfColumns):
                CGFloat(attributes.indexPath.section) * itemSize.height * CGFloat(numberOfRows)
        }
        
        var xCellOffset : CGFloat = CGFloat(attributes.indexPath.item % 7) * self.itemSize.width
        var yCellOffset :CGFloat = CGFloat(attributes.indexPath.item / 7) * self.itemSize.height
        
        if scrollDirection == .Horizontal {
            xCellOffset += stride
        } else {
            yCellOffset += stride
        }
        
        attributes.frame = CGRectMake(xCellOffset, yCellOffset, self.itemSize.width, self.itemSize.height)
    
    }
    
    func cachedHeaderSizeForSection(section: Int) -> CGSize {
        // We cache the header here so we dont call the delegate so much
        var headerSize = CGSizeZero
        if let cachedHeader  = currentHeader where cachedHeader.section == section {
            headerSize = cachedHeader.size
        } else {
            headerSize = delegate!.referenceSizeForHeaderInSection(section)
            currentHeader = (section, headerSize)
        }
        return headerSize
    }
    
    func sizeForitemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        let headerSize      = cachedHeaderSizeForSection(indexPath.section)
        let currentItemSize = itemSize
        let size            = CGSize(width: currentItemSize.width, height: (collectionView!.frame.height - headerSize.height) / CGFloat(numberOfRows))
        currentCell         = (section: indexPath.section, itemSize: size)
        return size
    }
    
    
    /// Returns an object initialized from data in a given unarchiver. self, initialized using the data in decoder.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Returns the content offset to use after an animation layout update or change.
    /// - Parameter proposedContentOffset: The proposed point for the upper-left corner of the visible content
    /// - returns: The content offset that you want to use instead
    public override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
        return proposedContentOffset
    }
    
    func clearCache() {
        headerCache.removeAll()
        cellCache.removeAll()
        currentHeader = nil
        currentCell = nil
        contentHeight = 0
        contentWidth = 0
    }
}