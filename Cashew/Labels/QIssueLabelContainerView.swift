//
//  QIssueLabelContainerView.swift
//  Issues
//
//  Created by Hicham Bouabdallah on 5/5/16.
//  Copyright © 2016 Hicham Bouabdallah. All rights reserved.
//

import Cocoa

class QIssueLabelContainerView: BaseView {
    
    private static let labelSpacing: CGFloat = 4.0
    
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
    
    private let moreLabel: QIssueLabelView = {
        let label = QIssueLabelView.instantiateFromNib()
        label.mode = .ColoredBackground
        label.hidden = true
        return label
    }()
    
    private var labelViews = [QIssueLabelView]()
    
    var labels: [QLabel]? {
        didSet {
            setupLabels()
        }
    }
    
    var mode: QIssueLabelViewMode = QIssueLabelViewMode.ColoredBackground {
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
    

    private func setup() {
        disableThemeObserver = true
        backgroundColor = NSColor.clearColor()
        setupManageButton()
        addSubview(moreLabel)
        
        labelViewPool.willBorrowObject = { [weak self] (label) in
            guard let strongSelf  = self else { return }
            label.hidden = false
            label.shouldAllowVibrancy = strongSelf.shouldAllowVibrancy
        }
        labelViewPool.willReturnObject = { [weak self] (label) in
            guard let strongSelf  = self else { return }
            label.hidden = true
            label.shouldAllowVibrancy = strongSelf.shouldAllowVibrancy
        }
    }
    
    private func setupLabels() {
        assert(NSThread.isMainThread())
        removeLabelViews()
        
        guard var labels = labels else { return }
        labels.sortInPlace({
            guard let name1 = $0.name, name2 = $1.name else { return false }
            return name1.compare(name2) == .OrderedAscending
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
                labelView.hidden = true
                counter += 1
                if let title = labelView.viewModel?.title {
                    mutableString.addObject(title)
                }
                continue
            }
            
            labelView.hidden = false
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
                previousLabel.hidden = true
                
                counter += 1
                moreLabel.viewModel = QIssueLabelViewModel(title: "+\(counter)", color: NSColor(calibratedWhite: 0, alpha: 0.20))
                if let title = previousLabel.viewModel?.title {
                    mutableString.addObject(title)
                }
                
                labelSize = moreLabel.labelSize()
                labelTop = bounds.height / 2.0 - labelSize.height / 2.0
            }
            
            moreLabel.frame = rect
            moreLabel.hidden = false
            if let tooltipLabels = mutableString.array as? [NSString] {
                moreLabel.toolTip = (tooltipLabels as NSArray).componentsJoinedByString("\n")
            }
        } else {
            moreLabel.hidden = true
        }
        
        super.layout()
    }
    
    private func removeLabelViews() {
        assert(NSThread.isMainThread())
        labelViews.forEach({ (labelView) in
            //guard let labelView = view as? QIssueLabelView where labelView != moreLabel else { return }
            //labelView.removeFromSuperview()
            labelViewPool.returnObject(labelView)
        })
        labelViews.removeAll()
    }
    
    private func updateLabelColors() {
        labelViews.forEach({ (labelView) in
            //guard let labelView = view as? QIssueLabelView where labelView != moreLabel else { return }
            labelView.mode = mode
        })
    }
    
    
    // MARK: UI Setup
    private func setupManageButton() {
        
    }
}


