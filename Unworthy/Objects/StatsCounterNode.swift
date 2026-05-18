import SpriteKit

final class StatsCounterNode: SKNode {
    private let label = SKLabelNode()
    private var lastKills = -1
    private var lastDeaths = -1

    override init() {
        super.init()
        label.fontName = FontLoader.getFont(fileName: "chiller.ttf") ?? "Helvetica-Bold"
        label.fontSize = 64
        label.fontColor = .white
        label.horizontalAlignmentMode = .right
        label.verticalAlignmentMode = .top
        addChild(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(kills: Int, deaths: Int) {
        guard kills != lastKills || deaths != lastDeaths else { return }
        lastKills = kills
        lastDeaths = deaths
        label.text = "Kills: \(kills)  Deaths: \(deaths)"
    }
}
