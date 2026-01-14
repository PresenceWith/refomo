//
//  TabNavigableTextEditor.swift
//  refomo
//

import SwiftUI
import UIKit

struct TabNavigableTextEditor: UIViewRepresentable {
    @Binding var text: String
    var isFocused: Bool
    var onFocusChange: (Bool) -> Void
    var onTabPressed: () -> Void
    var onShiftTabPressed: () -> Void

    func makeUIView(context: Context) -> TabAwareTextView {
        let tv = TabAwareTextView()
        tv.delegate = context.coordinator
        tv.onTabPressed = onTabPressed
        tv.onShiftTabPressed = onShiftTabPressed
        tv.font = .preferredFont(forTextStyle: .body)
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = false
        return tv
    }

    func updateUIView(_ tv: TabAwareTextView, context: Context) {
        if tv.text != text { tv.text = text }
        DispatchQueue.main.async {
            if self.isFocused && !tv.isFirstResponder { tv.becomeFirstResponder() }
            else if !self.isFocused && tv.isFirstResponder { tv.resignFirstResponder() }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TabNavigableTextEditor
        init(_ parent: TabNavigableTextEditor) { self.parent = parent }

        func textView(_ tv: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            text != "\t"
        }
        func textViewDidChange(_ tv: UITextView) { parent.text = tv.text }
        func textViewDidBeginEditing(_ tv: UITextView) { if !parent.isFocused { parent.onFocusChange(true) } }
        func textViewDidEndEditing(_ tv: UITextView) { if parent.isFocused { parent.onFocusChange(false) } }
    }
}

class TabAwareTextView: UITextView {
    var onTabPressed: (() -> Void)?
    var onShiftTabPressed: (() -> Void)?

    // Cached key commands
    private lazy var cachedKeyCommands: [UIKeyCommand] = {
        let tab = UIKeyCommand(input: "\t", modifierFlags: [], action: #selector(handleTab))
        tab.wantsPriorityOverSystemBehavior = true
        let shiftTab = UIKeyCommand(input: "\t", modifierFlags: .shift, action: #selector(handleShiftTab))
        shiftTab.wantsPriorityOverSystemBehavior = true
        return [tab, shiftTab]
    }()

    override var keyCommands: [UIKeyCommand]? { cachedKeyCommands }

    override func insertText(_ text: String) {
        if text == "\t" { onTabPressed?(); return }
        super.insertText(text)
    }

    @objc private func handleTab() { onTabPressed?() }
    @objc private func handleShiftTab() { onShiftTabPressed?() }
}

// MARK: - Keyboard Responder View

struct KeyboardResponderView: UIViewRepresentable {
    var isFocused: Bool
    var onFocusChange: (Bool) -> Void
    var onLeftArrow: (() -> Void)?
    var onRightArrow: (() -> Void)?
    var onTab: () -> Void
    var onShiftTab: () -> Void
    var onEnter: (() -> Void)?

    func makeUIView(context: Context) -> KeyboardResponderUIView {
        let v = KeyboardResponderUIView()
        v.onLeftArrow = onLeftArrow
        v.onRightArrow = onRightArrow
        v.onTab = onTab
        v.onShiftTab = onShiftTab
        v.onEnter = onEnter
        v.onFocusChange = onFocusChange
        return v
    }

    func updateUIView(_ v: KeyboardResponderUIView, context: Context) {
        v.shouldBecomeFirstResponder = isFocused
        DispatchQueue.main.async {
            if self.isFocused {
                if v.window != nil && !v.isFirstResponder { v.becomeFirstResponder() }
            } else if v.isFirstResponder {
                v.resignFirstResponder()
            }
        }
    }
}

class KeyboardResponderUIView: UIView {
    var onLeftArrow: (() -> Void)?
    var onRightArrow: (() -> Void)?
    var onTab: (() -> Void)?
    var onShiftTab: (() -> Void)?
    var onEnter: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?
    var shouldBecomeFirstResponder = false

    // Cached key commands - built lazily based on configured handlers
    private var _cachedKeyCommands: [UIKeyCommand]?
    private func buildKeyCommands() -> [UIKeyCommand] {
        var cmds: [UIKeyCommand] = []
        if onLeftArrow != nil {
            let c = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleLeft))
            c.wantsPriorityOverSystemBehavior = true
            cmds.append(c)
        }
        if onRightArrow != nil {
            let c = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleRight))
            c.wantsPriorityOverSystemBehavior = true
            cmds.append(c)
        }
        let tab = UIKeyCommand(input: "\t", modifierFlags: [], action: #selector(handleTab))
        tab.wantsPriorityOverSystemBehavior = true
        cmds.append(tab)
        let shiftTab = UIKeyCommand(input: "\t", modifierFlags: .shift, action: #selector(handleShiftTab))
        shiftTab.wantsPriorityOverSystemBehavior = true
        cmds.append(shiftTab)
        if onEnter != nil {
            let c = UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(handleEnter))
            c.wantsPriorityOverSystemBehavior = true
            cmds.append(c)
        }
        return cmds
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        if _cachedKeyCommands == nil { _cachedKeyCommands = buildKeyCommands() }
        return _cachedKeyCommands
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil && shouldBecomeFirstResponder && !isFirstResponder { becomeFirstResponder() }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }

    @objc private func handleLeft() { onLeftArrow?() }
    @objc private func handleRight() { onRightArrow?() }
    @objc private func handleTab() { onTab?() }
    @objc private func handleShiftTab() { onShiftTab?() }
    @objc private func handleEnter() { onEnter?() }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let r = super.becomeFirstResponder()
        if r { onFocusChange?(true) }
        return r
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        let r = super.resignFirstResponder()
        if r { onFocusChange?(false) }
        return r
    }
}
