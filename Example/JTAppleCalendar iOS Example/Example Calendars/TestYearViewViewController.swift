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
    
    @IBAction func tappedMe(_ sender: Any) {
        calendarView.reloadData()
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
        

        let dataSource = calendar.dataSourcefrom(configurationParameters: configParams)
        
        var g: [Any] = []

        for index in (0..<dataSource.count) {
            if index % 12 == 0 { g.append("Year") }
            g.append(dataSource[index])
        }

        return (configParams, g)
//        return (configParams, dataSource)
        
    }
    
  
    
    func calendar(_ calendar: JTACYearView, monthView: JTAppleMonthView, drawingFor rect: CGRect, with date: Date, dateOwner: DateOwner, monthIndex index: Int) -> (UIImage, CGRect)? {
        var retval:  (UIImage, CGRect) = (UIImage(), .zero)
        f.dateFormat = "d"
        
        if #available(iOSApplicationExtension 10.0, *) {
            // Draw text
//            if dateOwner == .thisMonth {
                let dateString = f.string(from: date)
                retval = (UIImage.text(dateString, rect: rect), rect)
//            }
            
            // Draw dotView
//            let c = Calendar(identifier: .gregorian)
//            if c.isDate(date, equalTo: Date(), toGranularity: .day) {
//                let v: CGFloat = 5
//                let r2 = CGRect(x: rect.midX - v/2, y: rect.maxY - 5, width: v, height: v)
//                let x = UIImage.circle(rect: r2)
//                retval.append((x, r2))
//            }
            
            // DrawSquares
//            retval.append((UIImage.rectangle(rect: rect), rect))
            
            
        } 
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


@available(iOSApplicationExtension 10.0, *)
extension UIImage {
    class func text(_ text: String, rect: CGRect) -> UIImage  {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        let img = renderer.image { ctx in

            let radius = rect.width
            let fontSize: CGFloat
            if radius >= 17.0 { fontSize = 11.0 }
            else if radius >= 16.0 { fontSize = 10.0 }
            else { fontSize = 8.0 }
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let font = UIFont(name: "HelveticaNeue", size: fontSize)!
            ctx.cgContext.addRect(rect)
            ctx.cgContext.drawPath(using: .stroke)
            
            text.draw(in: rect, withAttributes: [
                NSAttributedString.Key.font : font,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ])
            
            
        }
        return img
    }
    class func circle(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        let image = renderer.image { ctx in
            ctx.cgContext.setLineWidth(1)
            ctx.cgContext.setStrokeColor(UIColor.blue.cgColor)
            ctx.cgContext.setFillColor(UIColor.blue.cgColor)
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.drawPath(using: .fill)
        }
        return image
    }
    
    class func rectangle(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        
        let img = renderer.image { ctx in
            ctx.cgContext.setStrokeColor(UIColor.red.cgColor)
            ctx.cgContext.setLineWidth(1)
            
            ctx.cgContext.addRect(rect)
            ctx.cgContext.drawPath(using: .stroke)
        }
        return img
    }
}
