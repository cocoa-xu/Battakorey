import Cocoa

final class BattakoreyMenu: NSMenu {
    var preferencesHandler: (() -> Void)?

    private let presenter = BatteryMenuPresenter()
    private var layout: [String] = []
    private var rowViews: [BattakoreyMenuItem] = []
    private var hasBuiltMenu = false

    func prepare() {
        guard !hasBuiltMenu else { return }
        rebuild(with: [], detailSections: [])
    }

    func update(with battery: BatterySnapshot, visibility: BatteryMenuVisibility) {
        let sections = presenter.sections(for: battery, visibility: visibility)
        let detailSections = presenter.detailSections(for: battery, visibility: visibility)
        let newLayout = layout(for: sections, prefix: "main")
            + layout(for: detailSections, prefix: "details")
        let rows = sections.flatMap(\.rows) + detailSections.flatMap(\.rows)

        if hasBuiltMenu, layout == newLayout, rowViews.count == rows.count {
            for (view, row) in zip(rowViews, rows) {
                view.update(title: row.title, value: row.value)
            }
            return
        }

        rebuild(with: sections, detailSections: detailSections)
        layout = newLayout
    }

    private func rebuild(
        with sections: [BatteryMenuSection],
        detailSections: [BatteryMenuSection]
    ) {
        removeAllItems()
        rowViews.removeAll()
        hasBuiltMenu = true

        populate(sections, in: self)
        if !detailSections.isEmpty {
            if !sections.isEmpty {
                addItem(.separator())
            }
            let detailsItem = NSMenuItem(title: "Battery Internals", action: nil, keyEquivalent: "")
            let detailsMenu = NSMenu(title: "Battery Internals")
            populate(detailSections, in: detailsMenu)
            detailsItem.submenu = detailsMenu
            addItem(detailsItem)
        }

        if !sections.isEmpty || !detailSections.isEmpty {
            addItem(.separator())
        }
        let preferencesItem = NSMenuItem(
            title: "Preferences…",
            action: #selector(showPreferences),
            keyEquivalent: ","
        )
        preferencesItem.target = self
        addItem(preferencesItem)

        addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        addItem(quitItem)
    }

    private func populate(_ sections: [BatteryMenuSection], in menu: NSMenu) {
        for (index, section) in sections.enumerated() {
            if index > 0 {
                menu.addItem(.separator())
            }
            if let title = section.title {
                let header = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                header.isEnabled = false
                menu.addItem(header)
            }
            for row in section.rows {
                let item = NSMenuItem()
                let view = BattakoreyMenuItem(frame: NSRect(x: 0, y: 0, width: 340, height: 23))
                view.update(title: row.title, value: row.value)
                item.view = view
                menu.addItem(item)
                rowViews.append(view)
            }
        }
    }

    private func layout(for sections: [BatteryMenuSection], prefix: String) -> [String] {
        sections.flatMap { section in
            ["\(prefix):\(section.title ?? "")"] + section.rows.map { "\(prefix):\($0.id.rawValue)" }
        }
    }

    @objc private func showPreferences() {
        preferencesHandler?()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

final class BattakoreyMenuItem: NSView {
    private let titleLabel: NSTextField
    private let detailLabel: NSTextField

    override init(frame frameRect: NSRect) {
        let margin: CGFloat = 12
        let titleWidth = frameRect.width * 0.42
        titleLabel = NSTextField(frame: NSRect(
            x: margin,
            y: 0,
            width: titleWidth - margin,
            height: frameRect.height
        ))
        detailLabel = NSTextField(frame: NSRect(
            x: titleWidth,
            y: 0,
            width: frameRect.width - titleWidth - margin,
            height: frameRect.height
        ))
        super.init(frame: frameRect)

        configure(titleLabel)
        configure(detailLabel)
        detailLabel.alignment = .right
        addSubview(titleLabel)
        addSubview(detailLabel)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func update(title: String, value: String) {
        titleLabel.stringValue = title
        titleLabel.textColor = .labelColor
        detailLabel.stringValue = value
        detailLabel.textColor = .secondaryLabelColor
    }

    private func configure(_ label: NSTextField) {
        label.cell = BattakoreyTextFieldCell()
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.lineBreakMode = .byTruncatingTail
    }
}

final class BattakoreyTextFieldCell: NSTextFieldCell {
    private func verticallyCenteredFrame(_ rect: NSRect) -> NSRect {
        var titleRect = super.titleRect(forBounds: rect)
        let minimumHeight = cellSize(forBounds: rect).height
        titleRect.origin.y += (titleRect.height - minimumHeight) / 2
        titleRect.size.height = minimumHeight
        return titleRect
    }

    override func edit(
        withFrame rect: NSRect,
        in controlView: NSView,
        editor textObject: NSText,
        delegate: Any?,
        event: NSEvent?
    ) {
        super.edit(
            withFrame: verticallyCenteredFrame(rect),
            in: controlView,
            editor: textObject,
            delegate: delegate,
            event: event
        )
    }

    override func select(
        withFrame rect: NSRect,
        in controlView: NSView,
        editor textObject: NSText,
        delegate: Any?,
        start selectionStart: Int,
        length selectionLength: Int
    ) {
        super.select(
            withFrame: verticallyCenteredFrame(rect),
            in: controlView,
            editor: textObject,
            delegate: delegate,
            start: selectionStart,
            length: selectionLength
        )
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: verticallyCenteredFrame(cellFrame), in: controlView)
    }
}
