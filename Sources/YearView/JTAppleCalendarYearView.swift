//
//  JTAppleCalendarYearView.swift
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

public protocol JTAppleCalendarYearViewDelegate: class {
    func calendar(_ calendar: JTAppleCalendarYearView, cellForItemAt date: Date, indexPath: IndexPath) -> JTAppleMonthCell
    func calendar(_ calendar: JTAppleCalendarYearView,
                  monthView: JTAppleMonthView,
                  drawingFor segmentRect: CGRect,
                  with date: Date,
                  dateOwner: DateOwner,
                  monthIndexPath indexPath: IndexPath) -> (UIImage, CGRect)?
    func calendar(_ calendar: JTAppleCalendarYearView, sizeForItemAt indexPath: IndexPath) -> CGSize
}

extension JTAppleCalendarYearViewDelegate {
    func calendar(_ calendar: JTAppleCalendarYearView,
                  monthView: JTAppleMonthView,
                  drawingFor segmentRect: CGRect,
                  with date: Date,
                  dateOwner: DateOwner,
                  monthIndexPath indexPath: IndexPath) -> (UIImage, CGRect)? {
        return (UIImage(), .zero)
    }
    func calendar(_ calendar: JTAppleCalendarYearView, sizeForItemAt indexPath: IndexPath) -> CGSize { return .zero }
}

public protocol JTAppleCalendarYearViewDataSource: class {
    func configureCalendar(_ calendar: JTAppleCalendarYearView) -> (configurationParameters: ConfigurationParameters, months: [Any])
}


open class JTAppleCalendarYearView: UICollectionView {
    var configurationParameters = ConfigurationParameters(startDate: Date(), endDate: Date())
    var monthData: [Any] = []
    
    
    /// The object that acts as the delegate of the calendar year view.
    weak open var calendarDelegate: JTAppleCalendarYearViewDelegate?
    weak open var calendarDataSource: JTAppleCalendarYearViewDataSource? {
        didSet { setupYearViewCalendar() }
    }
    
    /// Workaround for Xcode bug that prevents you from connecting the delegate in the storyboard.
    /// Remove this extra property once Xcode gets fixed.
    @IBOutlet public var ibCalendarDelegate: AnyObject? {
        get { return calendarDelegate }
        set { calendarDelegate = newValue as? JTAppleCalendarYearViewDelegate }
    }
    
    /// Workaround for Xcode bug that prevents you from connecting the delegate in the storyboard.
    /// Remove this extra property once Xcode gets fixed.
    @IBOutlet public var ibCalendarDataSource: AnyObject? {
        get { return calendarDataSource }
        set { calendarDataSource = newValue as? JTAppleCalendarYearViewDataSource }
    }
    
    func dataSourcefrom(configurationParameters: ConfigurationParameters) -> [Any] {
        return JTAppleDateConfigGenerator.shared.setupMonthInfoDataForStartAndEndDate(configurationParameters).months
    }
    
    func setupYearViewCalendar() {
        guard let validConfig = calendarDataSource?.configureCalendar(self) else {
            print("Invalid datasource")
            return;
        }
        
        configurationParameters = validConfig.configurationParameters
        monthData               = validConfig.months
        dataSource = self
        delegate = self
    }
    
}

extension JTAppleCalendarYearView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return monthData.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let delegate = calendarDelegate,
            let date = configurationParameters.calendar.date(byAdding: .month, value: indexPath.item, to: configurationParameters.startDate),
            monthData.count > indexPath.item else {
                print("Invalid startup parameters. Exiting calendar setup.")
                assert(false)
                return UICollectionViewCell()
        }

        let configuredCell = delegate.calendar(self, cellForItemAt: date, indexPath: indexPath)
        
        if let monthData = monthData[indexPath.item] as? Month {
            configuredCell.setupWith(configurationParameters: configurationParameters,
                                     month: monthData,
                                     date: date,
                                     indexPath: indexPath,
                                     delegate: self)
        }
        
        return configuredCell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let size = calendarDelegate?.calendar(self, sizeForItemAt: indexPath) else {
            let width = (self.frame.width - 40) / 3
            let height = width
            return CGSize(width: width, height: height)
        }
        return size
    }
}

extension JTAppleCalendarYearView: JTAppleMonthCellDelegate {
    public func monthView(_ monthView: JTAppleMonthView, drawingFor segmentRect: CGRect, with date: Date, dateOwner: DateOwner, monthIndexPath: IndexPath)  -> (UIImage, CGRect)? {
        return calendarDelegate?.calendar(self, monthView: monthView, drawingFor: segmentRect, with: date, dateOwner: dateOwner, monthIndexPath: monthIndexPath)
    }
}
