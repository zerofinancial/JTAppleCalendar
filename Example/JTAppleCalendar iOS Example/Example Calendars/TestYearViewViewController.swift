//
//  TestYearViewViewController.swift
//  JTAppleCalendar
//
//  Created by Jeron Thomas on 2019-05-11.
//

import UIKit

class TestYearViewViewController: UIViewController {
    var cp: ConfigurationParameters!
    let c = Calendar(identifier: .gregorian)
    
    var sDate: Date!
    var eDate: Date!
    
    let f = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        f.dateFormat = "yyyy MM dd"
        
        sDate = f.date(from: "2019 03 01")!
        eDate = f.date(from: "2019 12 31")!
        cp = ConfigurationParameters(startDate: sDate, endDate: eDate)
    }
}


extension TestYearViewViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let range = c.dateComponents([.month], from: sDate, to: eDate)
        return range.month ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "myCell", for: indexPath) as! MyCell

        let date = c.date(byAdding: .month, value: indexPath.item, to: sDate)!
        
        f.dateFormat = "MMM"
        cell.monthLabel.text = f.string(from: date)
        
        cell.setupWith(configurationParameters: cp, index: indexPath.item)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 40) / 3
        let height = width
        return CGSize(width: width, height: height)
    }
    
    
}


class MyCell: UICollectionViewCell {
    @IBOutlet var monthView: JTAppleMonthCell!
    @IBOutlet var monthLabel: UILabel!
    
    func setupWith(configurationParameters: ConfigurationParameters, index: Int) {
        monthView.setupWith(configurationParameters: configurationParameters, index: index)
    }
}
