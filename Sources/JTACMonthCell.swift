//
//  JTACMonthCell.swift
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
public protocol JTACCellMonthViewDelegate: class {
    func monthView(_ monthView: JTACCellMonthView,
                  drawingFor segmentRect: CGRect,
                  with date: Date,
                  dateOwner: DateOwner,
                  monthIndex: Int)  -> (UIImage, CGRect)?
}

open class JTACMonthCell: UICollectionViewCell {
    @IBOutlet var monthView: JTACCellMonthView?
    weak var delegate: JTACCellMonthViewDelegate?
    
    func setupWith(configurationParameters: ConfigurationParameters,
                   month: Month,
                   date: Date,
                   delegate: JTACCellMonthViewDelegate) {
        guard let monthView = monthView else { assert(false); return }
        self.delegate = delegate
        monthView.setupWith(configurationParameters: configurationParameters,
                            month: month,
                            date: date,
                            delegate: self)
    }
}

extension JTACMonthCell: JTACCellMonthViewDelegate {
    public func monthView(_ monthView: JTACCellMonthView,
                          drawingFor segmentRect: CGRect,
                          with date: Date,
                          dateOwner: DateOwner,
                          monthIndex: Int) -> (UIImage, CGRect)? {
        return delegate?.monthView(monthView, drawingFor: segmentRect, with: date, dateOwner: dateOwner, monthIndex: monthIndex)
    }
}




open class JTACCellMonthView: UIView {
    var daysInSection: [Int: Int] = [:] // temporary caching
    var sectionInset = UIEdgeInsets.zero
    var month: Month!
    var monthDate: Date!
    var configurationParameters: ConfigurationParameters!
    
    var yCellOffset:CGFloat = 0
    var xCellOffset:CGFloat = 0
    var xStride:CGFloat = 0

    weak var delegate: JTACCellMonthViewDelegate?
    var scrollDirection: UICollectionView.ScrollDirection = .horizontal
    
    func setupWith(configurationParameters: ConfigurationParameters, month: Month, date: Date, delegate: JTACCellMonthViewDelegate? = nil) {
        self.configurationParameters = configurationParameters
        self.delegate = delegate
        self.month = month
        self.monthDate = date
        
        yCellOffset = 0
        xCellOffset = 0
        xStride = 0
        
        setNeedsDisplay()  // force reloading of the drawRect code to update the view.
    }
    
    func determineToApplyAttribs(month: Month) -> (xOffset: CGFloat, yOffset: CGFloat, width: CGFloat, height: CGFloat)? {
            
            let numberOfRowsForSection = month.maxNumberOfRowsForFull(developerSetRows: 6)
            let width = (frame.width - ((sectionInset.left / 7) + (sectionInset.right / 7))) / 7
            let height = (frame.height - sectionInset.top - sectionInset.bottom) / CGFloat(numberOfRowsForSection)
            
            let y = scrollDirection == .horizontal ? yCellOffset + sectionInset.top : yCellOffset
            return (xCellOffset + xStride, y, width, height)
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)


        for numberOfDaysInCurrentSection in month.sections {
            
            for dayCounter in 1...numberOfDaysInCurrentSection {
                guard let attribute = determineToApplyAttribs(month: month) else { continue }
            
                let rect = CGRect(x: attribute.xOffset, y: attribute.yOffset, width: attribute.width, height: attribute.height)

                guard let dateWithOwner = dateFromIndex(dayCounter - 1, month: month,
                                                        startOfMonthCache: configurationParameters.startDate,
                                                        endOfMonthCache: configurationParameters.endDate) else { continue }

                
                if let data = delegate?.monthView(self,
                                                  drawingFor: rect,
                                                  with: dateWithOwner.date,
                                                  dateOwner: dateWithOwner.owner,
                                                  monthIndex: month.index) {
                    data.0.draw(in: data.1)
                }

                xCellOffset += attribute.width
                
                if dayCounter == numberOfDaysInCurrentSection || dayCounter % maxNumberOfDaysInWeek == 0 {
                    // We are at the last item in the section
                    // && if we have headers
                    xCellOffset = sectionInset.left
                    yCellOffset += attribute.height
                }
            }
        }
    }
    
    func fontSizeFor(radius: CGFloat) -> CGFloat {
        if radius >= 17.0 {
            return 11.0
        } else if radius >= 16.0 {
            return 10.0
        } else {
            return 8.0
        }
    }
    
    private func dateFromIndex(_ index: Int, month: Month, startOfMonthCache: Date, endOfMonthCache: Date) -> (date: Date, owner: DateOwner)? { // Returns nil if date is out of scope
        let calendar = Calendar(identifier: .gregorian)
        // Calculate the offset
        let offSet = month.inDates
        
        let dayIndex = month.startDayIndex + index - offSet
        var dateOwner: DateOwner = .thisMonth
        let date: Date? = calendar.date(byAdding: .day, value: dayIndex, to: startOfMonthCache)
        
        
        
        if index >= offSet && index < month.numberOfDaysInMonth + offSet {
            // This is a month date
        } else if index < offSet {
            // This is a preDate
            
            if date! < startOfMonthCache {
                dateOwner = .previousMonthOutsideBoundary
            } else {
                dateOwner = .previousMonthWithinBoundary
            }
        } else {
            // This is a postDate
            
            
            if date! > endOfMonthCache {
                dateOwner = .followingMonthOutsideBoundary
            } else {
                dateOwner = .followingMonthWithinBoundary
            }
        }
        guard let validDate = date else { return nil }
        return (validDate, dateOwner)
    }
}


extension CGRect {
    var midPoint: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
