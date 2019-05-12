//
//  TestYearViewViewController.swift
//  JTAppleCalendar
//
//  Created by Jeron Thomas on 2019-05-11.
//

import UIKit

class TestYearViewViewController: UIViewController {
    var cp: ConfigurationParameters!
    var months: [Month] = []
    let c = Calendar(identifier: .gregorian)
    
    var sDate: Date!
    var eDate: Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dateConfigurator = JTAppleDateConfigGenerator()
        let f = DateFormatter()
        f.dateFormat = "yyyy MM dd"
        
        sDate = f.date(from: "2019 03 01")!
        eDate = f.date(from: "2019 12 31")!
        
        cp = ConfigurationParameters(startDate: sDate, endDate: eDate)
        let monthData = dateConfigurator.setupMonthInfoDataForStartAndEndDate(cp)

        self.months.append(contentsOf: monthData.months)
    }
    


}


extension TestYearViewViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return months.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "monthViewCell", for: indexPath) as! MonthViewCell
        let month = months[indexPath.item]
//        let date = c.date(byAdding: .month, value: indexPath.item, to: sDate)!
        cell.setupWith(month: month, monthDate: sDate)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 40) / 3
        let height = width
        return CGSize(width: width, height: height)
    }
    
    
}


class MonthViewCell: JTAppleMonthCell {
    
}
