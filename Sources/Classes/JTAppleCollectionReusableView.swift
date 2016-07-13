//
//  JTAppleCollectionReusableView.swift
//  Pods
//
//  Created by Jay Thomas on 2016-05-11.
//
//

/// The header view class of the calendar
public class JTAppleCollectionReusableView: UICollectionReusableView {
    var view: JTAppleHeaderView!

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// Returns an object initialized from data in a given unarchiver. self, initialized using the data in decoder.
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupHeaderView(headerViewXibs: [String], currentXib: String) {
        if view != nil { return }
        assert(headerViewXibs.count > 0, "Did you remember to register your xib file to JTAppleCalendarView? call the registerCellViewXib method on it because xib filename is nil")
        let viewObject = NSBundle.mainBundle().loadNibNamed(currentXib, owner: self, options: [:])
        assert(viewObject.count > 0, "your nib file name \(currentXib) could not be loaded)")
        
        guard let view = viewObject[0] as? JTAppleHeaderView else {
            print("xib file class does not conform to the protocol<JTAppleDayCellViewProtocol>")
            assert(false )
            return
        }
        self.view = view
        self.addSubview(view)
        update()
    }
    
    func update() {
        view!.frame = self.frame
        view!.center = CGPoint(x: self.bounds.size.width * 0.5, y: self.bounds.size.height * 0.5)
    }
}
