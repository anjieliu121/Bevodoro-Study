//
//  ThreeMatchViewController.swift
//  Bevodoro Study
//
//  Created by Anjie on 4/27/26.
//

import UIKit

final class ThreeMatchViewController: BaseViewController {
    private static let boardSize = 7

    private enum Tile: String, CaseIterable {
        case empty = ""
        case apple = "apple"
        case banana = "banana"
        case coin = "coin"
        case cookie = "cookie"
        case homework = "homework"
        case mango = "mango"
        case orange = "orange"
        case pill = "pill"
        case wheat = "wheat"

        static var playableCases: [Tile] {
            allCases.filter { $0 != .empty }
        }
    }

    private struct Position: Hashable {
        let row: Int
        let col: Int
    }

    private let promptContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "I need snacks and study wins. Match 3 tiles for me!"
        label.textColor = SettingsStyle.mainTitle
        label.font = SettingsTypography.sourGummy(size: 18, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let bevoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "NormalHead"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let boardContainer = UIView()
    private let boardStack = UIStackView()
    private let awardLabel = UILabel()
    private let resetButton = UIButton(type: .system)

    private var board: [[Tile]] = []
    private var buttons: [[UIButton]] = []
    private var selectedPosition: Position?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startNewGame()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = ""
        HapticsManager.shared.prepareForInteraction()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        promptContainer.addSubview(promptLabel)

        boardContainer.translatesAutoresizingMaskIntoConstraints = false
        boardContainer.backgroundColor = UIColor.white.withAlphaComponent(0.78)
        boardContainer.layer.cornerRadius = 16
        boardContainer.layer.masksToBounds = true

        boardStack.translatesAutoresizingMaskIntoConstraints = false
        boardStack.axis = .vertical
        boardStack.alignment = .fill
        boardStack.distribution = .fillEqually
        boardStack.spacing = 3

        boardContainer.addSubview(boardStack)

        awardLabel.translatesAutoresizingMaskIntoConstraints = false
        awardLabel.textAlignment = .center
        awardLabel.numberOfLines = 1
        awardLabel.font = SettingsTypography.sourGummy(size: 16, weight: .regular)
        awardLabel.textColor = SettingsStyle.mainTitle

        var configuration = UIButton.Configuration.filled()
        configuration.title = "Reset"
        configuration.baseBackgroundColor = SettingsStyle.accent
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = SettingsTypography.sourGummy(size: 17, weight: .semibold)
            return outgoing
        }
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.configuration = configuration
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        view.addSubview(promptContainer)
        view.addSubview(bevoImageView)
        view.addSubview(boardContainer)
        view.addSubview(awardLabel)
        view.addSubview(resetButton)

        NSLayoutConstraint.activate([
            promptContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            promptContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            promptContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            promptContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),

            promptLabel.topAnchor.constraint(equalTo: promptContainer.topAnchor, constant: 10),
            promptLabel.leadingAnchor.constraint(equalTo: promptContainer.leadingAnchor, constant: 10),
            promptLabel.trailingAnchor.constraint(equalTo: promptContainer.trailingAnchor, constant: -10),
            promptLabel.bottomAnchor.constraint(equalTo: promptContainer.bottomAnchor, constant: -10),

            bevoImageView.topAnchor.constraint(equalTo: promptContainer.bottomAnchor, constant: 6),
            bevoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bevoImageView.widthAnchor.constraint(equalToConstant: 200),
            bevoImageView.heightAnchor.constraint(equalToConstant: 150),

            boardContainer.topAnchor.constraint(equalTo: bevoImageView.bottomAnchor, constant: -8),
            boardContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            boardContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            boardContainer.heightAnchor.constraint(equalTo: boardContainer.widthAnchor),

            boardStack.topAnchor.constraint(equalTo: boardContainer.topAnchor, constant: 8),
            boardStack.leadingAnchor.constraint(equalTo: boardContainer.leadingAnchor, constant: 8),
            boardStack.trailingAnchor.constraint(equalTo: boardContainer.trailingAnchor, constant: -8),
            boardStack.bottomAnchor.constraint(equalTo: boardContainer.bottomAnchor, constant: -8),

            awardLabel.topAnchor.constraint(equalTo: boardContainer.bottomAnchor, constant: 8),
            awardLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            awardLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            resetButton.topAnchor.constraint(equalTo: awardLabel.bottomAnchor, constant: 8),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }

    private func startNewGame() {
        selectedPosition = nil
        awardLabel.text = ""
        buildInitialBoard()
        buildButtonsIfNeeded()
        renderBoard()
    }

    private func buildInitialBoard() {
        board = Array(
            repeating: Array(repeating: .apple, count: Self.boardSize),
            count: Self.boardSize
        )
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                var banned = Set<Tile>()
                if col >= 2, board[row][col - 1] == board[row][col - 2] {
                    banned.insert(board[row][col - 1])
                }
                if row >= 2, board[row - 1][col] == board[row - 2][col] {
                    banned.insert(board[row - 1][col])
                }
                board[row][col] = randomTile(excluding: banned)
            }
        }
    }

    private func buildButtonsIfNeeded() {
        guard buttons.isEmpty else { return }

        for row in 0..<Self.boardSize {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.alignment = .fill
            rowStack.distribution = .fillEqually
            rowStack.spacing = 3
            rowStack.translatesAutoresizingMaskIntoConstraints = false

            var buttonRow: [UIButton] = []
            for col in 0..<Self.boardSize {
                let button = UIButton(type: .system)
                button.translatesAutoresizingMaskIntoConstraints = false
                button.backgroundColor = UIColor.white.withAlphaComponent(0.9)
                button.layer.cornerRadius = 8
                button.layer.masksToBounds = true
                button.tag = row * Self.boardSize + col
                button.adjustsImageWhenHighlighted = false
                button.imageView?.contentMode = .scaleAspectFit
                button.addTarget(self, action: #selector(tileTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(button)
                buttonRow.append(button)
            }
            boardStack.addArrangedSubview(rowStack)
            buttons.append(buttonRow)
        }
    }

    @objc private func resetTapped() {
        HapticsManager.shared.selection()
        startNewGame()
    }

    @objc private func tileTapped(_ sender: UIButton) {
        let row = sender.tag / Self.boardSize
        let col = sender.tag % Self.boardSize
        let tapped = Position(row: row, col: col)

        if let selected = selectedPosition {
            if selected == tapped {
                selectedPosition = nil
                renderBoard()
                return
            }

            guard isAdjacent(selected, tapped) else {
                selectedPosition = tapped
                HapticsManager.shared.selection()
                renderBoard()
                return
            }

            performMove(from: selected, to: tapped)
        } else {
            selectedPosition = tapped
            HapticsManager.shared.selection()
            renderBoard()
        }
    }

    private func performMove(from start: Position, to end: Position) {
        swap(start, end)
        let firstMatches = findMatches()
        if firstMatches.isEmpty {
            swap(start, end)
            selectedPosition = nil
            HapticsManager.shared.warning()
            awardLabel.text = "No match yet - try another swap."
            renderBoard()
            return
        }

        selectedPosition = nil
        resolveMatches(startingWith: firstMatches)
        renderBoard()
    }

    private func resolveMatches(startingWith initialMatches: Set<Position>) {
        var currentMatches = initialMatches
        while !currentMatches.isEmpty {
            clear(matches: currentMatches)
            applyGravity()
            refill()
            currentMatches = findMatches()
        }
        let earned = 1
        awardCoins(earned)
        updateAwardMessage(earned: earned)
        HapticsManager.shared.success()
    }

    private func clear(matches: Set<Position>) {
        for position in matches {
            board[position.row][position.col] = .empty
        }
    }

    private func applyGravity() {
        for col in 0..<Self.boardSize {
            var writeRow = Self.boardSize - 1
            for row in stride(from: Self.boardSize - 1, through: 0, by: -1) {
                let tile = board[row][col]
                if tile != .empty {
                    board[writeRow][col] = tile
                    if writeRow != row {
                        board[row][col] = .empty
                    }
                    writeRow -= 1
                }
            }
            while writeRow >= 0 {
                board[writeRow][col] = .empty
                writeRow -= 1
            }
        }
    }

    private func refill() {
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize where board[row][col] == .empty {
                var banned = Set<Tile>()
                if col >= 2, board[row][col - 1] == board[row][col - 2] {
                    banned.insert(board[row][col - 1])
                }
                if row >= 2, board[row - 1][col] == board[row - 2][col] {
                    banned.insert(board[row - 1][col])
                }
                banned.insert(.empty)
                board[row][col] = randomTile(excluding: banned)
            }
        }
    }

    private func findMatches() -> Set<Position> {
        var matches = Set<Position>()

        for row in 0..<Self.boardSize {
            var col = 0
            while col < Self.boardSize {
                let tile = board[row][col]
                if tile == .empty {
                    col += 1
                    continue
                }
                var end = col + 1
                while end < Self.boardSize, board[row][end] == tile {
                    end += 1
                }
                if end - col >= 3 {
                    for matchedCol in col..<end {
                        matches.insert(Position(row: row, col: matchedCol))
                    }
                }
                col = end
            }
        }

        for col in 0..<Self.boardSize {
            var row = 0
            while row < Self.boardSize {
                let tile = board[row][col]
                if tile == .empty {
                    row += 1
                    continue
                }
                var end = row + 1
                while end < Self.boardSize, board[end][col] == tile {
                    end += 1
                }
                if end - row >= 3 {
                    for matchedRow in row..<end {
                        matches.insert(Position(row: matchedRow, col: col))
                    }
                }
                row = end
            }
        }

        return matches
    }

    private func randomTile(excluding: Set<Tile> = []) -> Tile {
        let candidates = Tile.playableCases.filter { !excluding.contains($0) }
        return candidates.randomElement() ?? .apple
    }

    private func swap(_ first: Position, _ second: Position) {
        let temp = board[first.row][first.col]
        board[first.row][first.col] = board[second.row][second.col]
        board[second.row][second.col] = temp
    }

    private func isAdjacent(_ first: Position, _ second: Position) -> Bool {
        let deltaRow = abs(first.row - second.row)
        let deltaCol = abs(first.col - second.col)
        return (deltaRow == 1 && deltaCol == 0) || (deltaRow == 0 && deltaCol == 1)
    }

    private func renderBoard() {
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                let tile = board[row][col]
                let button = buttons[row][col]
                let image = tile == .empty ? nil : UIImage(named: tile.rawValue)?.withRenderingMode(.alwaysOriginal)
                button.setImage(image, for: .normal)
                button.tintColor = .clear
                let isSelected = selectedPosition?.row == row && selectedPosition?.col == col
                button.layer.borderWidth = isSelected ? 2.5 : 0
                button.layer.borderColor = isSelected ? SettingsStyle.accent.cgColor : UIColor.clear.cgColor
            }
        }
    }

    private func awardCoins(_ amount: Int) {
        guard amount > 0 else { return }
        UserManager.shared.currentUser?.addCoins(amount)
        UserManager.shared.currentUser?.saveToFirestore()
    }

    private func updateAwardMessage(earned: Int) {
        let message = NSMutableAttributedString(string: "Matched! Earned ")
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "Coin")
        attachment.bounds = CGRect(x: 0, y: -3, width: 16, height: 16)
        message.append(NSAttributedString(attachment: attachment))
        message.append(NSAttributedString(string: " \(earned)"))
        awardLabel.attributedText = message
    }
}
