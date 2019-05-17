//
//  TestYearViewViewController.swift
//  JTAppleCalendar
//
//  Created by JayT on 2019-05-11.
//

import UIKit

class TestYearViewViewController: UIViewController {
    @IBOutlet var calendarView: JTACYearView!
    let f = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}


extension TestYearViewViewController: JTACYearViewDelegate, JTACYearViewDataSource {
    func calendar(_ calendar: JTACYearView, cellFor item: Any, at date: Date, indexPath: IndexPath) -> JTAppleMonthCell {
        if item is Month {
            let cell = calendar.dequeueReusableJTAppleMonthCell(withReuseIdentifier: "kkk", for: indexPath) as! MyCell
            f.dateFormat = "MMM"
            cell.monthLabel.text = f.string(from: date)
            return cell
        } else {
            let cell = calendar.dequeueReusableJTAppleMonthCell(withReuseIdentifier: "zzz", for: indexPath) as! YearHeaderCell
            f.dateFormat = "yyyy"
            cell.yearLabel.text = f.string(from: date)
            return cell
        }
    }
    
    
    
    func configureCalendar(_ calendar: JTACYearView) -> (configurationParameters: ConfigurationParameters, months: [Any]) {
        let df = DateFormatter()
        df.dateFormat = "yyyy MM dd"
        
        let sDate = df.date(from: "2019 01 01")!
        let eDate = df.date(from: "2050 05 31")!
        
        let configParams = ConfigurationParameters(startDate: sDate,
                                                   endDate: eDate,
                                                   numberOfRows: 6,
                                                   calendar: Calendar(identifier: .gregorian),
                                                   generateInDates: .forAllMonths,
                                                   generateOutDates: .tillEndOfGrid,
                                                   firstDayOfWeek: .sunday,
                                                   hasStrictBoundaries: true)
        
        // Get year data
        let dataSource = calendar.dataSourcefrom(configurationParameters: configParams)
        
        // Modify the data source to include a String every 12 data elements.
        // This string type will be used to add a header.
        var modifiedDataSource: [Any] = []
        for index in (0..<dataSource.count) {
            if index % 12 == 0 { modifiedDataSource.append("Year") }
            modifiedDataSource.append(dataSource[index])
        }

        return (configParams, modifiedDataSource)
    }
    
  
    
    func calendar(_ calendar: JTACYearView, monthView: JTAppleMonthView, drawingFor rect: CGRect, with date: Date, dateOwner: DateOwner, monthIndex index: Int) -> (UIImage, CGRect)? {
        f.dateFormat = "d"
        let dateString = f.string(from: date)
        let retval = (UIImage.text(dateString, rect: rect), rect)
        return retval
    }
    
    func calendar(_ calendar: JTACYearView, sizeFor item: Any) -> CGSize {
        if item is Month {
            let width = (calendar.frame.width - 41 ) / 3
            let height = width
            return CGSize(width: width, height: height)
        } else {
            let width = calendar.frame.width - 41
            let height:CGFloat  = 20
            return CGSize(width: width, height: height)
        }
    }
}


class MyCell: JTAppleMonthCell {
    @IBOutlet var monthLabel: UILabel!
}

class YearHeaderCell: JTAppleMonthCell {
    @IBOutlet var yearLabel: UILabel!
}

extension UIImage {
    class func text(_ text: String, rect: CGRect) -> UIImage  {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        let img = renderer.image { ctx in
            // Draw a box around the cells.
            ctx.cgContext.addRect(rect)
            ctx.cgContext.drawPath(using: .stroke)
            
            // Draw text on the cell
            let fontSize: CGFloat
            if rect.width >= 17.0 { fontSize = 11.0 }
            else if rect.width >= 16.0 { fontSize = 10.0 }
            else { fontSize = 8.0 }
            let font = UIFont(name: "HelveticaNeue", size: fontSize)!
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            text.draw(in: rect, withAttributes: [
                NSAttributedString.Key.font : font,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ])
        }
        return img
    }
}
