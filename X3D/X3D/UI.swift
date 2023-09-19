//
//  UI.swift
//  X3D
//
//  Created by Douglas McNamara on 9/14/23.
//

import AppKit

public var UIButtonColor = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
public var UIBackgroundColor = NSColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
public var UIForegroundColor = NSColor.black
public var UISelectionColor = NSColor.white
public var UIFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .light)

public extension NSWindow {
    
    var isFullscreen:Bool {
        (styleMask.rawValue & NSWindow.StyleMask.fullScreen.rawValue) != 0
    }
}

fileprivate class Panel : NSView {
    
    override var isOpaque: Bool {
        false
    }
    
    override var isFlipped: Bool {
        true
    }
}

fileprivate class Button : NSView {
    
    public var selected:Bool=false
    public var down=false
    
    private var _clicked=false
    private var _field:NSTextField?
    private var _down=false
    
    public init(caption:String) {
        super.init(frame: NSRect.zero)
        
        _field = NSTextField(string: caption)
        _field!.isBordered = false
        _field!.isSelectable = false
        _field!.isEditable = false
        _field!.frame = NSMakeRect(10, 10, 0, 0)
        _field!.drawsBackground = false
        
        self.wantsLayer = true
        self.layer = CAGradientLayer()

        addSubview(_field!)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public var field:NSTextField {
        _field!
    }
    
    public var clicked:Bool {
        let c = _clicked
        
        _clicked = false
        
        return c
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    override func mouseDown(with event: NSEvent) {
        var p = convert(event.locationInWindow, from: nil)
        
        p.x += frame.origin.x
        p.y += frame.origin.y
        
        if let _ = hitTest(p) {
            down = true
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        var p = convert(event.locationInWindow, from: nil)
        
        p.x += frame.origin.x
        p.y += frame.origin.y
        
        if let _ = hitTest(p) {
            _clicked = true
        }
        down = false
    }
}

fileprivate class TextField : NSView, NSTextFieldDelegate {
    
    private var _changed:String?
    private var _field:NSTextField?
    
    public init(width:CGFloat) {
        super.init(frame: NSRect.zero)
        
        _field = NSTextField(string: "")
        _field!.frame = NSMakeRect(10, 10, width, 0)
        _field!.isBordered = false
        _field!.delegate = self
        
        addSubview(_field!)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public var field:NSTextField {
        _field!
    }
    
    public var changed:String? {
        let c = _changed
        
        _changed = nil
        
        return c
    }
    
    func controlTextDidChange(_ obj: Notification) {
        _changed = _field!.stringValue
    }
}

fileprivate class List : NSView {
    
    private var _selected:Int = -1
    private var _changed:Int?
    
    public init() {
        super.init(frame: NSRect.zero)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public var selected:Int {
        get { _selected }
        set {
            _selected = newValue
            _changed = nil
        }
    }
    
    public var changed:Int? {
        let c = _changed
        
        _changed = nil
        
        return c
    }
    
    override var isFlipped: Bool {
        true
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
    
    override func mouseDown(with event: NSEvent) {
        let p =  convert(event.locationInWindow, from: nil)
        
        if let view = hitTest(p) {
            if let field = view as? NSTextField {
                let i = subviews.firstIndex(of: field)!
                
                if i != _selected {
                    _selected = i
                    _changed = i
                }
            }
        }
    }
}

public class UI {
    
    private var _panel=Panel()
    private var _keyedViews=[String:NSView]()
    private var _views=[NSView]()
    private var _startX:CGFloat=0
    private var _x:CGFloat=0
    private var _y:CGFloat=0
    private var _maxHeight:CGFloat=0
    
    public init() {
    }
    
    public var panel:NSView {
        _panel
    }
    
    public func begin() {
        _startX = 0
        _x = 0
        _y = 0
        _maxHeight = 0
        _views.append(contentsOf: _keyedViews.values)
    }
    
    public func moveRightOf(key:String, gap:CGFloat) {
        if let view = _keyedViews[key] {
            _startX = view.frame.origin.x + view.frame.size.width + gap
            _x = _startX
            _y = view.frame.origin.y
            _maxHeight = 0
        }
    }
    
    public func addRow(gap:CGFloat) {
        _x = _startX
        _y = _y + _maxHeight + gap
        _maxHeight = 0
    }
    
    public func button(key:String, gap:CGFloat, caption:String, selected:Bool) -> Bool {
        var button=_keyedViews[key] as? Button
        
        if button == nil {
            
            button = Button(caption: caption)
            
            _keyedViews[key] = button
            _panel.addSubview(button!)
        }
        button!.isHidden = false
        
        button!.selected = selected
        
        _views.removeAll { v in v == button }
        
        button!.layer!.borderWidth = 1
        button!.layer!.borderColor = (selected) ? UISelectionColor.cgColor : UIForegroundColor.cgColor
        
        button!.field.textColor = (selected) ? UISelectionColor : UIForegroundColor
        button!.field.font = UIFont
        button!.field.sizeToFit()
        
        let f = button!.field.frame
        let layer = button!.layer as! CAGradientLayer
        let c = UIButtonColor.cgColor.components
        var r = c![0]
        var g = (c!.count >= 3) ? c![1] : r
        var b = (c!.count >= 3) ? c![2] : r
        if button!.down {
            r *= 2
            g *= 2
            b *= 2
        }
        let color1 = CGColor(red: r * 0.75, green: g * 0.75, blue: b * 0.75, alpha: 1)
        let color2 = CGColor(red: r * 1.50, green: g * 1.50, blue: b * 1.50, alpha: 1)
        
        layer.colors = [ color1, color2 ]
        layer.startPoint = NSMakePoint(0, 0)
        layer.endPoint = NSMakePoint(0, 1)
        layer.locations = [ 0, 1 ]
        
        button!.frame = NSMakeRect(_x + gap, _y, f.width + 20, f.height + 20)
        _x += gap + button!.frame.width
        
        _maxHeight = max(button!.frame.height, _maxHeight)
        
        return button!.clicked
    }
    
    public func field(key:String, gap:CGFloat, width:CGFloat, caption:String, intValue:Int, reset:Bool) -> Int? {
        var r:Int?
        
        if let result = field(key: key, gap: gap, width: width, caption: caption, text: "\(intValue)", reset: reset) {
            if let x = Int(result) {
                r = x
            }
        }
        return r
    }
    
    public func field(key:String, gap:CGFloat, width:CGFloat, caption:String, realValue:Float, reset:Bool) -> Float? {
        var r:Float?
        
        if let result = field(key: key, gap: gap, width: width, caption: caption, text: "\(realValue)", reset: reset) {
            if let x = Float(result) {
                r = x
            }
        }
        return r
    }
    
    public func field(key:String, gap:CGFloat, width:CGFloat, caption:String, vec2Value:Vec2, reset:Bool) -> Vec2? {
        var r:Vec2?
        
        if let result = field(key: key, gap: gap, width: width, caption: caption, text: "\(vec2Value)", reset: reset) {
            let tokens = result.components(separatedBy: CharacterSet.whitespaces)
            
            if tokens.count >= 2 {
                if let x = Float(tokens[0]), let y = Float(tokens[1]) {
                    r = Vec2(x, y)
                }
            }
        }
        return r
    }
    
    public func field(key:String, gap:CGFloat, width:CGFloat, caption:String, vec3Value:Vec3, reset:Bool) -> Vec3? {
        var r:Vec3?
        
        if let result = field(key: key, gap: gap, width: width, caption: caption, text: "\(vec3Value)", reset: reset) {
            let tokens = result.components(separatedBy: CharacterSet.whitespaces)
            
            if tokens.count >= 3 {
                if let x = Float(tokens[0]), let y = Float(tokens[1]), let z = Float(tokens[2]) {
                    r = Vec3(x, y, z)
                }
            }
        }
        return r
    }
    
    public func field(key:String, gap:CGFloat, width:CGFloat, caption:String, vec4Value:Vec4, reset:Bool) -> Vec4? {
        var r:Vec4?
        
        if let result = field(key: key, gap: gap, width: width, caption: caption, text: "\(vec4Value)", reset: reset) {
            let tokens = result.components(separatedBy: CharacterSet.whitespaces)
            
            if tokens.count >= 4 {
                if let x = Float(tokens[0]), let y = Float(tokens[1]), let z = Float(tokens[2]), let w = Float(tokens[3]) {
                    r = Vec4(x, y, z, w)
                }
            }
        }
        return r
    }
    
    public func field(key:String, gap:CGFloat, width:CGFloat, caption:String, text:String, reset:Bool) -> String? {
        var view:NSView?=_keyedViews[key]
        var added=false
        var field:TextField?
        var fieldCaption:NSTextField?
        
        if view == nil {
            
            view = NSView(frame: NSRect.zero)
            
            field = TextField(width: width)
            
            view!.addSubview(field!)
            
            fieldCaption = NSTextField(string: caption)
            fieldCaption!.frame = NSMakeRect(10 + width + 10, 10, 0, 0)
            fieldCaption!.isEditable = false
            fieldCaption!.isBordered = false
            fieldCaption!.isSelectable = false
            fieldCaption!.drawsBackground = false
            
            view!.addSubview(fieldCaption!)
            
            _keyedViews[key] = view!
            _panel.addSubview(view!)
            
            added = true
        } else {
            field = view!.subviews[0] as? TextField
            fieldCaption = view!.subviews[1] as? NSTextField
        }
        view!.isHidden = false
        
        _views.removeAll { v in v == view }
        
        field!.wantsLayer = true
        field!.layer!.borderWidth = 1
        field!.layer!.borderColor = UIForegroundColor.cgColor
        field!.layer!.backgroundColor = UIBackgroundColor.cgColor
        
        fieldCaption!.textColor = UISelectionColor
        fieldCaption!.font = UIFont
        fieldCaption!.sizeToFit()
        
        let f = field!.field.frame
        
        field!.field.textColor = UIForegroundColor
        field!.field.backgroundColor = UIBackgroundColor
        field!.field.font = UIFont
        
        if reset || added {
            field!.field.stringValue = text
            field!.field.sizeToFit()
        }
        
        field!.field.frame = NSMakeRect(10, 10, f.width, field!.field.frame.size.height)
        field!.frame = NSMakeRect(0, 0, f.width + 20, f.height + 20)
        
        fieldCaption!.frame = NSMakeRect(field!.frame.origin.x + field!.frame.width + 5, 10, fieldCaption!.frame.width, fieldCaption!.frame.height)
        
        view!.frame = NSMakeRect(_x + gap, _y, field!.frame.width + fieldCaption!.frame.width + 5, field!.frame.height)
        _x += gap + view!.frame.width
        
        _maxHeight = max(_maxHeight, view!.frame.height)
        
        return field!.changed
    }
    
    public func list(key:String, gap:CGFloat, width:CGFloat, height:CGFloat, items:inout [Any], selected:Int) -> Int? {
        var list=_keyedViews[key] as? NSScrollView
        
        if list == nil {
            
            list = NSScrollView()
            list!.documentView = List()
            
            _keyedViews[key] = list
            _panel.addSubview(list!)
        }
        list!.isHidden = false
        
        _views.removeAll { v in v == list }
        
        list!.wantsLayer = true
        list!.layer!.borderWidth = 1
        list!.layer!.borderColor = UIForegroundColor.cgColor
        list!.layer!.backgroundColor = UIBackgroundColor.cgColor
        
        list!.contentView.backgroundColor = UIBackgroundColor
        
        list!.frame = NSMakeRect(_x + gap, _y, width, height)
        _x += gap + width
        
        let listView = list!.documentView as! List
        
        var rebuild = listView.subviews.count != items.count
        
        if !rebuild {
            for i in 0..<listView.subviews.count {
                let field = listView.subviews[i] as! NSTextField
                let item = "\(items[i])"
                
                if field.stringValue != item {
                    rebuild = true
                    break
                }
            }
        }
        
        if selected > -2 {
            listView.selected = selected
        }
        
        if rebuild {
            let x:CGFloat = 10
            var y:CGFloat = 10
            var w:CGFloat = 0
            
            while !listView.subviews.isEmpty {
                listView.subviews[0].removeFromSuperview()
            }
            for item in items {
                let field = NSTextField(string: "\(item)")
                
                field.font = UIFont
                field.backgroundColor = UIBackgroundColor
                field.isEditable = false
                field.isBordered = false
                field.textColor = UIForegroundColor
                field.isSelectable = false
                
                field.sizeToFit()
                field.frame = NSMakeRect(x, y, list!.frame.width, field.frame.size.height)
                
                w = max(x + w, field.frame.size.width)
                
                listView.addSubview(field)
                
                y += field.frame.size.height + 5
            }
            listView.frame = NSMakeRect(0, 0, w, y)
        }
        
        for i in 0..<listView.subviews.count {
            let field = listView.subviews[i] as! NSTextField
            
            if i == listView.selected {
                field.textColor = UISelectionColor
            } else {
                field.textColor = UIForegroundColor
            }
        }
        
        _maxHeight = max(list!.frame.height, _maxHeight)
        
        return listView.changed
    }
    
    public func end() {
        for view in _views {
            view.isHidden = true
        }
        _views.removeAll(keepingCapacity: true)
        
        _x = 0
        _y = 0
        
        for view in panel.subviews {
            if !view.isHidden {
                let x = view.frame.origin.x + view.frame.size.width
                let y = view.frame.origin.y + view.frame.size.height
                
                _x = max(x, _x)
                _y = max(y, _y)
            }
        }
        panel.frame = NSMakeRect(0, 0, _x, _y)
    }
    
    public static func layout(gap:CGFloat, center:NSView, north:NSView?, south:NSView?, east:NSView?, west:NSView?) {
        var f = center.window!.contentView!.frame
        
        if let north = north {
            var n = north.frame
            
            n = NSMakeRect(gap, f.height - n.height - gap, n.width, n.height)
            f = NSMakeRect(f.origin.x, f.origin.y, f.width, f.height - n.height - gap * 2)
            
            north.frame = n
            
            if north.superview == nil {
                center.window!.contentView!.addSubview(north)
            }
        }
        
        if let south = south {
            var s = south.frame
            
            s = NSMakeRect(gap, gap, s.width, s.height)
            f = NSMakeRect(f.origin.x, f.origin.y + gap * 2 + s.height, f.width, f.height - s.height - gap * 2)
            
            south.frame = s
            
            if south.superview == nil {
                center.window!.contentView!.addSubview(south)
            }
        }
        
        if let east = east {
            var e = east.frame
            let g = (north != nil) ? 0 : gap
            
            e = NSMakeRect(f.width - e.width - gap, f.origin.y + f.height - e.height - g, e.width, e.height)
            f = NSMakeRect(f.origin.x, f.origin.y, f.width - e.width - gap * 2, f.height)
            
            east.frame = e
            
            if east.superview == nil {
                center.window!.contentView!.addSubview(east)
            }
        }
        
        if let west = west {
            var w = west.frame
            let g = (north != nil) ? 0 : gap
            
            w = NSMakeRect(gap, f.origin.y + f.height - w.height - g, w.width, w.height)
            f = NSMakeRect(f.origin.x + gap * 2 + w.width, f.origin.y, f.width - w.width - gap * 2, f.height)
            
            west.frame = w
            
            if west.superview == nil {
                center.window!.contentView!.addSubview(west)
            }
        }
        
        center.frame = f
    }
}
