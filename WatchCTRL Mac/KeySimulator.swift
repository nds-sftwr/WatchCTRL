import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

enum KeySimulator {
    // macOS virtual key codes (from Events.h / Carbon HIToolbox)
    private static let keyCodes: [String: CGKeyCode] = [
        "1": 0x12,      // kVK_ANSI_1
        "2": 0x13,      // kVK_ANSI_2
        "3": 0x14,      // kVK_ANSI_3
        "4": 0x15,      // kVK_ANSI_4
        "space": 0x31,  // kVK_Space
        "up": 0x7E,     // kVK_UpArrow
        "down": 0x7D,   // kVK_DownArrow
        "left": 0x7B,   // kVK_LeftArrow
        "right": 0x7C,  // kVK_RightArrow
        "return": 0x24, // kVK_Return
        "f5": 0x60,     // kVK_F5
        "r": 0x0F,      // kVK_ANSI_R
    ]

    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Key Simulation

    static func simulateKeyPress(_ keyCode: CGKeyCode) {
        guard hasAccessibilityPermission else { return }

        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    static func simulateKeyWithModifier(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        guard hasAccessibilityPermission else { return }

        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyDown?.flags = modifiers
        keyUp?.flags = modifiers
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    static func simulateMediaKey(_ keyType: Int32) {
        guard hasAccessibilityPermission else { return }

        // NX_KEYTYPE_PLAY = 16, etc.
        // System-defined media key events use a specific data format
        let keyDown = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyType << 16) | (0xa << 8)),
            data2: -1
        )
        let keyUp = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyType << 16) | (0xb << 8)),
            data2: -1
        )
        keyDown?.cgEvent?.post(tap: .cghidEventTap)
        keyUp?.cgEvent?.post(tap: .cghidEventTap)
    }

    static func simulateScroll(direction: ScrollDirection) {
        guard hasAccessibilityPermission else { return }

        let scrollAmount: Int32 = direction == .down ? -5 : 5
        let scrollEvent = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .line,
            wheelCount: 1,
            wheel1: scrollAmount,
            wheel2: 0,
            wheel3: 0
        )
        scrollEvent?.post(tap: .cghidEventTap)
    }

    // MARK: - Action Dispatch

    static func executeAnkiAction(_ action: String) {
        switch action {
        case "anki_1":
            simulateKeyPress(keyCodes["1"]!)
        case "anki_2":
            simulateKeyPress(keyCodes["2"]!)
        case "anki_3":
            simulateKeyPress(keyCodes["3"]!)
        case "anki_4":
            simulateKeyPress(keyCodes["4"]!)
        case "anki_space":
            simulateKeyPress(keyCodes["space"]!)
        default:
            break
        }
    }

    static func executeGestureAction(_ action: String) {
        switch action {
        case "scroll_down":
            simulateScroll(direction: .down)
        case "scroll_up":
            simulateScroll(direction: .up)
        case "tap":
            simulateKeyPress(keyCodes["return"]!)
        case "back":
            // Cmd+[ for browser/app back navigation
            simulateKeyWithModifier(keyCode: keyCodes["left"]!, modifiers: .maskCommand)
        case "refresh":
            // Cmd+R for refresh
            simulateKeyWithModifier(keyCode: keyCodes["r"]!, modifiers: .maskCommand)
        case "play_pause":
            simulateMediaKey(16) // NX_KEYTYPE_PLAY
        default:
            break
        }
    }

    enum ScrollDirection {
        case up, down
    }
}
