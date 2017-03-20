//
//  JTAppleCalendarLayoutProtocol.swift
//  JTAppleCalendar
//
//  Created by JayT on 2016-10-02.
//
//


protocol JTAppleCalendarLayoutProtocol: class {
    var shouldClearCacheOnInvalidate: Bool {get set}
    var allowsDateCellStretching: Bool {get set}
    var itemSizeWasSet: Bool {get set}
    var cellSize: CGSize {get set}
    
    var minimumInteritemSpacing: CGFloat {get set}
    var minimumLineSpacing: CGFloat {get set}
    
    var scrollDirection: UICollectionViewScrollDirection {get set}
    var cellCache: [Int: [(Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)]] {get set}
    var headerCache: [Int: (Int, Int, CGFloat, CGFloat, CGFloat, CGFloat)] {get set}
    var sectionSize: [CGFloat] {get set}
    var updatedLayoutCellSize: CGSize { get }
    func targetContentOffsetForProposedContentOffset(_ proposedContentOffset: CGPoint) -> CGPoint
    func sectionFromOffset(_ theOffSet: CGFloat) -> Int
    func sizeOfContentForSection(_ section: Int) -> CGFloat
    func indexPath(direction: SegmentDestination, of section:Int, item: Int) -> IndexPath?
}
