//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation

class EmojiReactorsTableView: UITableView {
    struct ReactorItem {
        let address: SignalServiceAddress
        let conversationColorName: ConversationColorName
        let displayName: String
        let emoji: String
    }

    private var reactorItems = [ReactorItem]() {
        didSet { reloadData() }
    }

    init() {
        super.init(frame: .zero, style: .plain)

        dataSource = self
        backgroundColor = Theme.actionSheetBackgroundColor
        separatorStyle = .none

        register(EmojiReactorCell.self, forCellReuseIdentifier: EmojiReactorCell.reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(for reactions: [OWSReaction], transaction: SDSAnyReadTransaction) {
        reactorItems = reactions.compactMap { reaction in
            let thread = TSContactThread.getWithContactAddress(reaction.reactor, transaction: transaction)
            let displayName = contactsManager.displayName(for: reaction.reactor, transaction: transaction)

            return ReactorItem(
                address: reaction.reactor,
                conversationColorName: thread?.conversationColorName ?? .default,
                displayName: displayName,
                emoji: reaction.emoji
            )
        }
    }
}

extension EmojiReactorsTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reactorItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: EmojiReactorCell.reuseIdentifier, for: indexPath)
        guard let contactCell = cell as? EmojiReactorCell else {
            owsFailDebug("unexpected cell type")
            return cell
        }

        guard let item = reactorItems[safe: indexPath.row] else {
            owsFailDebug("unexpected indexPath")
            return cell
        }

        contactCell.backgroundColor = .clear
        contactCell.configure(item: item)

        return contactCell
    }
}

private class EmojiReactorCell: UITableViewCell {
    static let reuseIdentifier = "EmojiReactorCell"

    let avatarView = ConversationAvatarView(diameter: 36,
                                            localUserAvatarMode: .asUser)
    let nameLabel = UILabel()
    let emojiLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        layoutMargins = UIEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        contentView.addSubview(avatarView)
        avatarView.autoPinLeadingToSuperviewMargin()
        avatarView.autoPinHeightToSuperviewMargins()

        contentView.addSubview(nameLabel)
        nameLabel.autoPinLeading(toTrailingEdgeOf: avatarView, offset: 8)
        nameLabel.autoPinHeightToSuperviewMargins()

        emojiLabel.font = .boldSystemFont(ofSize: 24)
        contentView.addSubview(emojiLabel)
        emojiLabel.autoPinLeading(toTrailingEdgeOf: nameLabel, offset: 8)
        emojiLabel.setContentHuggingHorizontalHigh()
        emojiLabel.autoPinHeightToSuperviewMargins()
        emojiLabel.autoPinTrailingToSuperviewMargin()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: EmojiReactorsTableView.ReactorItem) {

        nameLabel.textColor = Theme.primaryTextColor

        emojiLabel.text = item.emoji

        if item.address.isLocalAddress {
            nameLabel.text = NSLocalizedString("REACTIONS_DETAIL_YOU", comment: "Text describing the local user in the reaction details pane.")
        } else {
            nameLabel.text = item.displayName
        }

        avatarView.configureWithSneakyTransaction(address: item.address)
    }
}
