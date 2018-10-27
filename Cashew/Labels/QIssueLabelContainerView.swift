//
//  QIssueLabelContainerView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/5/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class QIssueLabelContainerView: BaseView {
    
    fileprivate static let labelSpacing: CGFloat = 4.0
    
    let labelViewPool: ObjectPool = ObjectPool<QIssueLabelView>() {
        let labelView = QIssueLabelView.instantiateFromNib()
        return labelView
    }
    
    override var shouldAllowVibrancy: Bool {
        didSet {
            labelViews.forEach({ (label) in
                label.shouldAllowVibrancy = shouldAllowVibrancy
            })
            moreLabel.shouldAllowVibrancy = shouldAllowVibrancy
        }
    }
    
    fileprivate let moreLabel: QIssueLabelView = {
        let label = QIssueLabelView.instantiateFromNib()
        label.mode = .coloredBackground
        label.isHidden = true
        return label
    }()
    
    fileprivate var labelViews = [QIssueLabelView]()
    
    var labels: [QLabel]? {
        didSet {
            setupLabels()
        }
    }
    
    var mode: QIssueLabelViewMode = QIssueLabelViewMode.coloredBackground {
        didSet {
            updateLabelColors()
        }
    }
    
    required init() {
        super.init(frame: NSRect.zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    // MARK: layout
    

    fileprivate func setup() {
        disableThemeObserver = true
        backgroundColor = NSColor.clear
        setupManageButton()
        addSubview(moreLabel)
        
        labelViewPool.willBorrowObject = { [weak self] (label) in
            guard let strongSelf  = self else { return }
            label.isHidden = false
            label.shouldAllowVibrancy = strongSelf.shouldAllowVibrancy
        }
        labelViewPool.willReturnObject = { [weak self] (label) in
            guard let strongSelf  = self else { return }
            label.isHidden = true
            label.shouldAllowVibrancy = strongSelf.shouldAllowVibrancy
        }
    }
    
    fileprivate func setupLabels() {
        assert(Thread.isMainThread)
        removeLabelViews()
        
        guard var labels = labels else { return }
        labels.sort(by: {
            guard let name1 = $0.name, let name2 = $1.name else { return false }
            return name1.compare(name2) == .orderedAscending
        })
        labels.forEach({ (label: QLabel) -> () in
            let labelView = labelViewPool.borrowObject() //QIssueLabelView.instantiateFromNib()
            if let labelName = label.name {
                labelView.viewModel = QIssueLabelViewModel(title: labelName, color: NSColor(fromHexadecimalValue: label.color))
                labelView.objectValue = label
                addSubview(labelView)
                labelViews.append(labelView)
            }
        })
        
        needsLayout = true
        layoutSubtreeIfNeeded()
    }
    
    
    override func layout() {
        
        let width = bounds.width
        
        guard width > 0 else {
            super.layout()
            return
        }
        
        var xOffset: CGFloat = 0.0
        var counter: Int = 0
        
        let mutableString = NSMutableOrderedSet()
        for labelView in labelViews {
            
            let labelSize = labelView.labelSize()
            let labelTop = bounds.height / 2.0 - labelSize.height / 2.0
            let rect = CGRectIntegralMake(x: xOffset, y: labelTop, width: labelSize.width, height: labelSize.height)
            
            if rect.maxX > width || counter != 0 {
                labelView.isHidden = true
                counter += 1
                if let title = labelView.viewModel?.title {
                    mutableString.add(title)
                }
                continue
            }
            
            labelView.isHidden = false
            labelView.frame = rect
            labelView.mode = mode
            xOffset += labelSize.width + QIssueLabelContainerView.labelSpacing
        }
        
        if counter > 0 {
            moreLabel.viewModel = QIssueLabelViewModel(title: "+\(counter)", color: NSColor(calibratedWhite: 0, alpha: 0.20))
            
            var labelSize = moreLabel.labelSize()
            var labelTop = bounds.height / 2.0 - labelSize.height / 2.0
            var rect = CGRectIntegralMake(x: xOffset, y: labelTop, width: labelSize.width, height: labelSize.height)
            
            var positionIndex: Int = labelViews.count - 1 - counter
            while rect.maxX > width {
                let previousLabel = labelViews[positionIndex]
                let previousLabelRect = previousLabel.frame
                rect = CGRectIntegralMake(x: previousLabelRect.minX, y: labelTop, width: labelSize.width, height: labelSize.height)
                positionIndex -= 1
                previousLabel.isHidden = true
                
                counter += 1
                moreLabel.viewModel = QIssueLabelViewModel(title: "+\(counter)", color: NSColor(calibratedWhite: 0, alpha: 0.20))
                if let title = previousLabel.viewModel?.title {
                    mutableString.add(title)
                }
                
                labelSize = moreLabel.labelSize()
                labelTop = bounds.height / 2.0 - labelSize.height / 2.0
            }
            
            moreLabel.frame = rect
            moreLabel.isHidden = false
            if let tooltipLabels = mutableString.array as? [NSString] {
                moreLabel.toolTip = (tooltipLabels as NSArray).componentsJoined(by: "\n")
            }
        } else {
            moreLabel.isHidden = true
        }
        
        super.layout()
    }
    
    fileprivate func removeLabelViews() {
        assert(Thread.isMainThread)
        labelViews.forEach({ (labelView) in
            //guard let labelView = view as? QIssueLabelView where labelView != moreLabel else { return }
            //labelView.removeFromSuperview()
            labelViewPool.returnObject(labelView)
        })
        labelViews.removeAll()
    }
    
    fileprivate func updateLabelColors() {
        labelViews.forEach({ (labelView) in
            //guard let labelView = view as? QIssueLabelView where labelView != moreLabel else { return }
            labelView.mode = mode
        })
    }
    
    
    // MARK: UI Setup
    fileprivate func setupManageButton() {
        
    }
}


