//
//  KeyboardCoordinator.swift
//  Swift Browser
//
//  Created by opencode on 06/02/26.
//

import AppKit

final class KeyboardCoordinator: NSObject {
    private var moveAction: ((Int) -> Void)?
    private var openAction: (() -> Void)?
    private var escAction: (() -> Void)?
    private var copyURLAction: (() -> Void)?
    private var deleteAction: (() -> Void)?
    private var monitor: Any?

    init(
        moveAction: @escaping (Int) -> Void,
        openAction: @escaping () -> Void,
        escAction: @escaping () -> Void,
        copyURLAction: @escaping () -> Void,
        deleteAction: @escaping () -> Void
    ) {
        self.moveAction = moveAction
        self.openAction = openAction
        self.escAction = escAction
        self.copyURLAction = copyURLAction
        self.deleteAction = deleteAction
        super.init()
        setupMonitor()
    }

    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    private func setupMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.isARepeat { return event }

            switch event.keyCode {
            case KeyCode.upArrow:
                self.moveAction?(-1)
                return nil
            case KeyCode.downArrow:
                self.moveAction?(1)
                return nil
            case KeyCode.enter:
                self.openAction?()
                return nil
            case KeyCode.delete:
                self.deleteAction?()
                return nil
            case KeyCode.escape:
                self.escAction?()
                return nil
            default:
                break
            }

            if event.modifierFlags.contains(.command) && event.characters == "c" {
                self.copyURLAction?()
                return nil
            }

            return event
        }
    }

    private enum KeyCode {
        static let upArrow: UInt16 = 126
        static let downArrow: UInt16 = 125
        static let enter: UInt16 = 36
        static let delete: UInt16 = 51
        static let escape: UInt16 = 53
    }
}
