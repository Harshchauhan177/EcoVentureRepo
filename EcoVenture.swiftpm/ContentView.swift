import SwiftUI

// Add this class before the ContentView struct
class GameState: ObservableObject {
    @Published var highScore: Int = 0
    @Published var currentLevel: Int = 1
    @Published var maxUnlockedLevel: Int = 1
    
    let maxLevels = 50
    
    @Published var playedDates: Set<Date> = []
    @Published var currentStreak: Int = 0
    @Published var rewards: [Date] = []
    
    // Add new properties for nature activities
    @Published var natureActivities: [Date: NatureActivity] = [:]
    
    @Published var coins: Int = 0
    let coinsPerActivity: Int = 50  // Reward amount for each activity
    
    let bonusCoinsForStreak: Int = 100
    @Published var showBonusAlert: Bool = false
    
    func updateHighScore(_ newScore: Int) {
        if newScore > highScore {
            highScore = newScore
        }
    }
    
    func unlockNextLevel() {
        if currentLevel == maxUnlockedLevel && maxUnlockedLevel < maxLevels {
            maxUnlockedLevel += 1
        }
    }
    
    func recordGamePlay() {
        let today = Calendar.current.startOfDay(for: Date())
        playedDates.insert(today)
        updateStreak()
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentDate = today
        var streak = 1
        
        // Count backwards from today to find the streak
        while true {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            if playedDates.contains(previousDay) {
                streak += 1
                currentDate = previousDay
            } else {
                break
            }
        }
        
        currentStreak = streak
        
        // Check for weekly reward and bonus coins
        if streak >= 7 {
            let rewardDate = calendar.date(byAdding: .day, value: -6, to: today)!
            if !rewards.contains(rewardDate) {
                rewards.append(rewardDate)
                // Add bonus coins
                addCoins(bonusCoinsForStreak)
                showBonusAlert = true
            }
        }
    }
    
    func isForestTheme(for level: Int) -> Bool {
        let levelGroup = (level - 1) / 2  // Group levels in pairs
        return levelGroup % 2 == 1  // Alternate between themes every 2 levels
    }
    
    func addCoins(_ amount: Int) {
        coins += amount
    }
    
    func addNatureActivity(_ entry: ActivityEntry, for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        if var existingActivity = natureActivities[startOfDay] {
            existingActivity.entries.append(entry)
            natureActivities[startOfDay] = existingActivity
        } else {
            let newActivity = NatureActivity(date: startOfDay, entries: [entry])
            natureActivities[startOfDay] = newActivity
        }
        
        playedDates.insert(startOfDay)
        updateStreak()
        
        // Add coins reward
        addCoins(coinsPerActivity)
    }
    
    func getNatureActivity(for date: Date) -> NatureActivity? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return natureActivities[startOfDay]
    }
    
    func getCoinsCostForLevel(_ level: Int) -> Int {
        // Base cost is 100 coins, increases by 50 coins per level
        return 75 + ((level - 2) * 25)  // Level 2 costs 100, Level 3 costs 150, Level 4 costs 200, etc.
    }
    
    func canUnlockLevel(level: Int) -> Bool {
        return coins >= getCoinsCostForLevel(level)
    }
    
    func unlockLevelWithCoins(level: Int) {
        let cost = getCoinsCostForLevel(level)
        if coins >= cost && level <= maxLevels {
            coins -= cost
            maxUnlockedLevel = max(maxUnlockedLevel, level)
        }
    }
}

// Add this struct after the GameState class
struct Fireball: Identifiable {
    let id = UUID()
    var position: CGFloat
    var positionY: CGFloat
    var rotation: Double
    let size: CGFloat = 30
}

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var selectedTab = 0
    @State private var isPresented = false

    init() {
        // Customize the tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 0.7)  // Light blue with transparency
        
        // Customize the normal and selected item colors
        appearance.stackedLayoutAppearance.normal.iconColor = .white.withAlphaComponent(0.6)
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
//            InfoView()
//                .tabItem {
//                    Label("Info", systemImage: "info.circle")
//                }
//                .tag(0)

            GameView(isPresented: $isPresented, gameState: gameState)
                .tabItem {
                    Label("Game", systemImage: "gamecontroller")
                }
                .tag(1)

            PollutionAwarenessView(gameState: gameState)
                .tabItem {
                    Label("Stop Pollution", systemImage: "leaf")
                }
                .tag(2)
        }
        .fullScreenCover(isPresented: $isPresented) {
            FullScreenView(isPresented: $isPresented,
                         gameState: gameState)
        }
    }
}

//// MARK: - First View
//struct InfoView: View {
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("About the Game")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .padding()
//                Text("This game helps raise awareness about keeping water bodies clean by collecting waste before it pollutes the water.")
//                    .multilineTextAlignment(.center)
//                    .padding()
//            }
//            .navigationTitle("Game🏏")
//        }
//    }
//}

// MARK: - Second View
struct GameView: View {
    @Binding var isPresented: Bool
    @ObservedObject var gameState: GameState
    @State private var showCustomLockAlert = false
    @State private var selectedLockedLevel = 0
    @State private var showInsufficientCoinsAlert = false
    
    let columns = [
        GridItem(.adaptive(minimum: 230, maximum: 250), spacing: 30)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Pass the current theme to DynamicBackground
                DynamicBackground(isForestTheme: gameState.isForestTheme(for: gameState.currentLevel))
                
                // Add clouds for consistency
                CloudsView()
                
                // Add theme-specific background
                VStack {
                    Spacer()
                    if gameState.isForestTheme(for: gameState.currentLevel) {
                        // Forest background
                        ForestView()
                    } else {
                        // River background
                        ZStack {
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                            
                            WaveView(waveOffset1: 0, waveOffset2: 0, waveOffset3: 0)
                                .frame(height: 40)
                                .offset(y: -50)
                        }
                    }
                }
                
                ScrollView {
                    VStack {
                        Text(gameState.isForestTheme(for: gameState.currentLevel) ?
                            "Forest Adventure 🌳" : "River Cleanup 🌊")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding()
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                        
                        Text("Select Level")
                            .font(.title3)
                            .padding()
                            .foregroundColor(.black)
                            .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 2)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(1...gameState.maxLevels, id: \.self) { level in
                                Button(action: {
                                    if level > gameState.maxUnlockedLevel {
                                        selectedLockedLevel = level
                                        showCustomLockAlert = true
                                    } else {
                                        gameState.currentLevel = level
                                        isPresented.toggle()
                                    }
                                }) {
                                    VStack {
                                        if level > gameState.maxUnlockedLevel {
                                            LockedLevelView(level: level)
                                        } else if level == 1 {
                                            FirstLevelView(
                                                level: level,
                                                isForestTheme: gameState.isForestTheme(for: level),
                                                description: getLevelDescription(level)
                                            )
                                        } else if gameState.isForestTheme(for: level) {
                                            ForestLevelView(
                                                level: level,
                                                description: getLevelDescription(level)
                                            )
                                        } else {
                                            RiverLevelView(
                                                level: level,
                                                description: getLevelDescription(level),
                                                backgroundColor: getThemeBackgroundColor(level: level)
                                            )
                                        }
                                    }
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Add the custom popup
                if showCustomLockAlert {
                    LockLevelPopup(
                        isPresented: $showCustomLockAlert,
                        level: selectedLockedLevel,
                        currentCoins: gameState.coins,
                        requiredCoins: gameState.getCoinsCostForLevel(selectedLockedLevel),
                        onUnlock: {
                            gameState.unlockLevelWithCoins(level: selectedLockedLevel)
                        },
                        showInsufficientCoins: $showInsufficientCoinsAlert
                    )
                }
            }
            .navigationTitle("pollution awareness")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                gameState.isForestTheme(for: gameState.currentLevel) ?
                    Color.green.opacity(0.3) :
                    Color.blue.opacity(0.3),
                for: .navigationBar
            )
            .alert("Insufficient Coins", isPresented: $showInsufficientCoinsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You need \(gameState.getCoinsCostForLevel(selectedLockedLevel)) coins to unlock this level.\nCurrent balance: \(gameState.coins) coins")
            }
        }
    }
    
    // Update the color scheme based on the theme
    func getThemeBackgroundColor(level: Int) -> Color {
        if gameState.isForestTheme(for: level) {
            // Darker forest theme colors
            switch level {
            case 1...10: return Color(red: 0.1, green: 0.3, blue: 0.1)  // Dark forest green
            case 11...20: return Color(red: 0.15, green: 0.35, blue: 0.15)
            case 21...30: return Color(red: 0.2, green: 0.4, blue: 0.2)
            case 31...40: return Color(red: 0.25, green: 0.45, blue: 0.25)
            case 41...50: return Color(red: 0.3, green: 0.5, blue: 0.3)
            default: return Color(red: 0.1, green: 0.3, blue: 0.1)
            }
        } else {
            // River theme colors
            switch level {
            case 1...10: return .blue
            case 11...20: return Color(red: 0.2, green: 0.4, blue: 0.8)
            case 21...30: return Color(red: 0.3, green: 0.5, blue: 0.9)
            case 31...40: return Color(red: 0.4, green: 0.6, blue: 1.0)
            case 41...50: return Color(red: 0.5, green: 0.7, blue: 1.0)
            default: return .blue
            }
        }
    }
    
    // Update level descriptions to match themes
    func getLevelDescription(_ level: Int) -> String {
        let targetScore = 5 + ((level - 1) * 3)
        let speed = String(format: "%.1f", min(5.0 + (Double(level) * 0.8), 40.0))
        let powerLoss = min(20 + (level / 2), 40)
        let maxMissed = max(6 - (level / 10), 3)
        
        let themePrefix = gameState.isForestTheme(for: level) ? "Forest" : "River"
        
        switch level {
        case 1...10:
            return "\(themePrefix) Level\nCollect \(targetScore) items\nSpeed: \(speed)"
        case 11...20:
            return "\(themePrefix) Challenge\nCollect \(targetScore) items\nPower Loss: \(powerLoss)"
        case 21...30:
            return "Advanced \(themePrefix)\nCollect \(targetScore) items\nChallenging!"
        case 31...40:
            return "Expert \(themePrefix)\nCollect \(targetScore) items\nVery Hard!"
        case 41...50:
            return "Master \(themePrefix)\nCollect \(targetScore) items\nExtreme!"
        default:
            return ""
        }
    }
}

// MARK: - Third View
struct PollutionAwarenessView: View {
    @ObservedObject var gameState: GameState
    
    var body: some View {
        NavigationView {
            VStack {
                CalendarView(gameState: gameState)
            }
            .navigationTitle("Pollution  👾")
        }
    }
}

// MARK: - FullScreen Game View
struct FullScreenView: View {
    @Binding var isPresented: Bool
    @ObservedObject var gameState: GameState
    
    @State private var boatPosition: CGFloat = 150
    @State private var waste: [Waste] = []
    @State private var score: Int = 0
    @State private var power: Int = 100
    @State private var missedWaste: Int = 0
    @State private var isGameOver: Bool = false
    @State private var isGameWon: Bool = false
    @State private var airplanePosition: CGFloat = 50
    @State private var airplaneDirection: CGFloat = 1
    
    // Add these new state variables for wave animation
    @State private var waveOffset1: CGFloat = 0
    @State private var waveOffset2: CGFloat = 0
    @State private var waveOffset3: CGFloat = 0
    
    // Add these new state variables for birds and sun
    @State private var birdPositions: [(CGFloat, CGFloat)] = []
    @State private var sunRotation: Double = 0
    
    // Add these new state variables in FullScreenView
    @State private var carpetPositionY: CGFloat = UIScreen.main.bounds.height - 131
    
    let wasteSpeed: CGFloat = 10.0
    let airplaneSpeed: CGFloat = 10.0
    
    @State private var gameTimer: Timer? = nil

    // Update the trashSymbols array to temporarily use SF Symbols
    private let trashSymbols = [
        (symbol: "trash.circle.fill", color: Color(red: 0.3, green: 0.3, blue: 0.3)),
        (symbol: "cup.and.saucer.fill", color: Color(red: 0.4, green: 0.4, blue: 0.4)),
        (symbol: "doc.fill", color: Color(red: 0.5, green: 0.5, blue: 0.5)),
        (symbol: "bag.fill", color: Color(red: 0.35, green: 0.35, blue: 0.35)),
        (symbol: "leaf.fill", color: Color(red: 0.45, green: 0.45, blue: 0.45)),
        (symbol: "drop.fill", color: Color(red: 0.4, green: 0.4, blue: 0.4))
    ]

    @State private var fireballs: [Fireball] = []  // Add this property
    
    var levelConfig: (targetScore: Int, wasteSpeed: CGFloat, spawnRate: Int, powerLoss: Int, maxMissed: Int, catchRadius: CGFloat) {
        let level = gameState.currentLevel
        
        // Calculate increasing difficulty
        let targetScore = 5 + ((level - 1) * 3) // More items to collect
        let baseSpeed = 5.0 + (Double(level) * 0.8) // Faster speed increase
        let speed = min(baseSpeed, 40.0) // Cap at higher speed
        let spawnRate = max(20 - (level / 2), 2) // More frequent spawns (changed from 35 to 20)
        
        // Additional difficulty parameters
        let powerLoss = min(20 + (level / 2), 40) // Increasing power loss
        let maxMissed = max(6 - (level / 10), 3) // Decreasing allowed misses
        let catchRadius = max(60 - Double(level), 30) // Decreasing catch area
        
        return (targetScore, CGFloat(speed), spawnRate, powerLoss, Int(maxMissed), CGFloat(catchRadius))
    }
    
    // Add this computed property to determine the theme
    var shouldShowForestTheme: Bool {
        let levelGroup = (gameState.currentLevel - 1) / 2  // Group levels in pairs
        return levelGroup % 2 == 1  // Alternate between themes every 2 levels
    }
    
    // Add this computed property
    private var shouldUseFireballs: Bool {
        gameState.isForestTheme(for: gameState.currentLevel)
    }
    
    // Add a computed property for power loss per miss
    private var powerLossPerMiss: Int {
        return 100 / levelConfig.maxMissed  // Distribute power loss evenly across max misses
    }
    
    var body: some View {
        ZStack {
            DynamicBackground(isForestTheme: shouldShowForestTheme)
            
            SunView(rotation: sunRotation)
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        sunRotation = 360
                    }
                }
            
            CloudsView()
            
            // Use shouldShowForestTheme instead of isForestTheme
            if shouldShowForestTheme {
                // Forest theme
                ForestView()
            } else {
                // Original river theme
                VStack {
                    Spacer()
                    ZStack {
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(height: 60)
                        
                        WaveView(waveOffset1: waveOffset1, waveOffset2: waveOffset2, waveOffset3: waveOffset3)
                            .frame(height: 40)
                            .offset(y: -50)
                            .mask(
                                Rectangle()
                                    .frame(height: 40)
                            )
                    }
                }
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        waveOffset1 = UIScreen.main.bounds.width
                    }
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        waveOffset2 = UIScreen.main.bounds.width
                    }
                    withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                        waveOffset3 = UIScreen.main.bounds.width
                    }
                }
            }
            
            // Add fireballs or waste based on theme
            if shouldUseFireballs {
                ForEach(fireballs) { fireball in
                    FireballView(fireball: fireball)
                }
            } else {
                ForEach(waste) { wasteItem in
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 40, height: 40)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                        
                        Image(systemName: wasteItem.symbol)  // Changed to systemName
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(wasteItem.color)  // Added color
                            .rotationEffect(.degrees(wasteItem.rotation))
                    }
                    .position(x: wasteItem.position, y: wasteItem.positionY + 40)
                }
            }

            AirplaneView(position: airplanePosition, direction: airplaneDirection)
            
            // Update the vehicle display
            if shouldShowForestTheme {
                FlyingCarpetView(position: $boatPosition, positionY: $carpetPositionY)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Update X position with bounds checking
                                self.boatPosition = min(max(value.location.x, 30), UIScreen.main.bounds.width - 30)
                                
                                // Update Y position with bounds checking
                                // Limit vertical movement between top and bottom of screen
                                let minY = UIScreen.main.bounds.height * 0.2 // Top 20% of screen
                                let maxY = UIScreen.main.bounds.height - 50  // Bottom of screen with padding
                                self.carpetPositionY = min(max(value.location.y, minY), maxY)
                            }
                    )
            } else {
                BoatView(position: $boatPosition)
                    .gesture(DragGesture()
                        .onChanged { value in
                            self.boatPosition = min(max(value.location.x, 30), UIScreen.main.bounds.width - 30)
                        })
            }

            VStack {
                // Game stats
                HStack(spacing: 5) {
                    // Exit button with new styling
                    Button(action: { isPresented.toggle() }) {
                        VStack(spacing: 5) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("EXIT")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        )
                    }
                    
                    GameStatView(
                        title: "LEVEL",
                        value: "\(gameState.currentLevel)",
                        color: .orange
                    )
                    
                    GameStatView(
                        title: "SCORE",
                        value: "\(score)/\(levelConfig.targetScore)",
                        color: .green
                    )
                    
                    GameStatView(
                        title: "POWER",
                        value: "\(power)%",
                        color: power > 50 ? .blue : (power > 25 ? .orange : .red)
                    )
                    
                    GameStatView(
                        title: "MISSED",
                        value: "\(missedWaste)/\(levelConfig.maxMissed)",
                        color: missedWaste < levelConfig.maxMissed - 1 ? .purple : .red
                    )
                }
                .padding(.top, 0)
                
                Spacer()
            }

            if isGameOver {
                VStack {
                    Text("Game Over!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("You missed \(missedWaste) waste items!")
                        .padding()
                    Button(action: resetGame) {
                        Text("Play Again")
                            .fontWeight(.bold)
                            .padding()
                            .frame(width: 200)
                            .background(Color.yellow.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 10)
                }
                .padding(30)
                .background(Color.brown)
                .cornerRadius(20)
                .padding()
            } else if isGameWon {
                VStack {
                    Text("Level Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("You caught \(score) waste items!")
                        .padding()
                    
                    if gameState.currentLevel < gameState.maxLevels {
                        Button(action: {
                            gameState.currentLevel += 1
                            resetGame()
                        }) {
                            Text("Next Level")
                                .fontWeight(.bold)
                                .padding()
                                .frame(width: 200)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 5)
                    }
                    
                    Button(action: resetGame) {
                        Text("Play Again")
                            .fontWeight(.bold)
                            .padding()
                            .frame(width: 200)
                            .background(Color.yellow.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 5)
                }
                .padding(30)
                .background(Color.brown)
                .cornerRadius(20)
                .padding()
            }
        }
        .onAppear {
            startGame()
        }
    }
    
    func startGame() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            Task {
                await updateGame()
            }
        }
    }

    @MainActor
    func updateGame() {
        // Update airplane movement speed based on level
        let airplaneSpeedMultiplier = min(1.0 + (Double(gameState.currentLevel) * 0.1), 2.5)
        airplanePosition += airplaneSpeed * airplaneDirection * CGFloat(airplaneSpeedMultiplier)
        
        if airplanePosition > UIScreen.main.bounds.width - 50 || airplanePosition < 50 {
            airplaneDirection *= -1
        }

        // Spawn waste/fireballs with level-specific rate
        if Int.random(in: 1...levelConfig.spawnRate) == 1 {
            if shouldUseFireballs {
                // Spawn fireball from airplane
                let fireball = Fireball(
                    position: airplanePosition,
                    positionY: 100,  // Adjust this value based on airplane position
                    rotation: Double.random(in: 0...360)
                )
                fireballs.append(fireball)
            } else {
                // Updated waste spawning logic for river theme - spawn from airplane
                let randomSymbol = trashSymbols.randomElement()!
                let waste = Waste(
                    position: airplanePosition,  // Changed to spawn from airplane position
                    positionY: 100,  // Changed to match airplane height
                    rotation: Double.random(in: 0...360),
                    symbol: randomSymbol.symbol,
                    color: randomSymbol.color
                )
                self.waste.append(waste)
            }
        }

        // Update positions and check collisions
        if shouldUseFireballs {
            fireballs = fireballs.compactMap { fireball in
                var updatedFireball = fireball
                updatedFireball.positionY += levelConfig.wasteSpeed
                
                // Check collision with flying carpet using actual carpet position
                if abs(updatedFireball.positionY - carpetPositionY) < 30 &&
                   abs(updatedFireball.position - boatPosition) < levelConfig.catchRadius {
                    score += 1
                    if score >= levelConfig.targetScore {
                        isGameWon = true
                        gameState.unlockNextLevel()
                        gameState.recordGamePlay()
                    }
                    return nil
                }
                
                // Remove if passed bottom of screen
                if updatedFireball.positionY > UIScreen.main.bounds.height {
                    missedWaste += 1
                    // Update power based on misses
                    power = max(0, 100 - (missedWaste * powerLossPerMiss))
                    if missedWaste >= levelConfig.maxMissed {
                        power = 0  // Ensure power is zero when max misses reached
                        isGameOver = true
                    }
                    return nil
                }
                
                return updatedFireball
            }
        } else {
            // Updated waste update logic for river theme
            waste = waste.compactMap { wasteItem in
                var updatedWaste = wasteItem
                updatedWaste.positionY += levelConfig.wasteSpeed
                
                // Check collision with boat
                let boatY = UIScreen.main.bounds.height - 131
                if abs(updatedWaste.positionY - boatY) < 40 &&
                   abs(updatedWaste.position - boatPosition) < levelConfig.catchRadius + 20 {
                    score += 1
                    if score >= levelConfig.targetScore {
                        isGameWon = true
                        gameState.unlockNextLevel()
                        gameState.recordGamePlay()
                    }
                    return nil
                }
                
                // Remove if passed bottom of screen
                if updatedWaste.positionY > UIScreen.main.bounds.height {
                    missedWaste += 1
                    // Update power based on misses
                    power = max(0, 100 - (missedWaste * powerLossPerMiss))
                    if missedWaste >= levelConfig.maxMissed {
                        power = 0  // Ensure power is zero when max misses reached
                        isGameOver = true
                    }
                    return nil
                }
                
                return updatedWaste
            }
        }

        if isGameOver || isGameWon {
            gameState.updateHighScore(score)
            gameTimer?.invalidate()
        }
    }

    func resetGame() {
        boatPosition = 150
        carpetPositionY = UIScreen.main.bounds.height - 131
        waste = []
        fireballs = []
        score = 0
        power = 100  // Reset power to 100%
        missedWaste = 0
        isGameOver = false
        isGameWon = false
        airplanePosition = 50
        airplaneDirection = 1
        startGame()
    }

    // Add this function to create random bird positions
    private func createBirds() {
        birdPositions = (0...5).map { _ in
            (
                CGFloat.random(in: -50...UIScreen.main.bounds.width),
                CGFloat.random(in: 100...300)
            )
        }
    }

    // Add FireballView
    struct FireballView: View {
        let fireball: Fireball
        
        var body: some View {
            ZStack {
                // Fireball appearance
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.orange, .red]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: fireball.size, height: fireball.size)
                    .overlay(
                        Circle()
                            .stroke(Color.yellow, lineWidth: 2)
                    )
                    .shadow(color: .orange.opacity(0.5), radius: 5)
                
                // Flame effect
                ForEach(0..<3) { i in
                    Image(systemName: "flame.fill")
                        .foregroundColor(.yellow)
                        .offset(y: CGFloat(i * 5))
                        .rotationEffect(.degrees(fireball.rotation))
                        .scaleEffect(1.0 - CGFloat(i) * 0.2)
                }
            }
            .position(x: fireball.position, y: fireball.positionY)
        }
    }
}

// MARK: - Supporting Views
struct Waste: Identifiable {
    let id = UUID()
    var position: CGFloat
    var positionY: CGFloat
    var rotation: Double
    var symbol: String
    var color: Color
}

struct BoatView: View {
    @Binding var position: CGFloat
    
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: 60, height: 20)
                .foregroundColor(.pink)
                .cornerRadius(10)
            
            Rectangle()
                .frame(width: 50, height: 10)
                .foregroundColor(.pink)
                .cornerRadius(5)
                .offset(y: -10)
            
            Image(systemName: "person.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.yellow)
                .position(x:201, y: UIScreen.main.bounds.height - 514)
        }
        .position(x: position, y: UIScreen.main.bounds.height - 131)  // Changed from -130 to -110
    }
}

struct AirplaneView: View {
    var position: CGFloat
    var direction: CGFloat
    
    var body: some View {
        Image(systemName: "airplane")
            .resizable()
            .frame(width: 60, height: 60)  // Made airplane bigger
            .foregroundColor(.gray)
            .rotationEffect(.degrees(direction == 1 ? 0 : 180))
            .position(x: position, y: 100)  // Moved airplane higher
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
    }
}

// Updated WaveView for more pronounced waves
struct WaveView: View {
    var waveOffset1: CGFloat
    var waveOffset2: CGFloat
    var waveOffset3: CGFloat
    
    var body: some View {
        ZStack {
            // Multiple wave layers with more pronounced amplitudes
            WaveShape(offset: waveOffset1, amplitude: 8, frequency: 0.3)
                .fill(Color.blue.opacity(0.4))
            
            WaveShape(offset: waveOffset2, amplitude: 10, frequency: 0.4)
                .fill(Color.blue.opacity(0.3))
            
            WaveShape(offset: waveOffset3, amplitude: 7, frequency: 0.5)
                .fill(Color.blue.opacity(0.2))
        }
    }
}

// Updated WaveShape for smoother waves
struct WaveShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat
    var frequency: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        
        // Use smaller stride for smoother waves
        for x in stride(from: 0, through: rect.width, by: 0.5) {
            let relativeX = x/rect.width
            let normalizedX = relativeX * .pi * 2 * frequency
            let y = sin(normalizedX + Double(offset/rect.width) * .pi * 2) * Double(amplitude)
            path.addLine(to: CGPoint(x: x, y: rect.midY + CGFloat(y)))
        }
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        
        return path
    }
}

// Add these new views for sun and birds
struct SunView: View {
    var rotation: Double
    
    var body: some View {
        ZStack {
            // Sun core
            Circle()
                .fill(Color.yellow)
                .frame(width: 45, height: 45)
            
            // Sun rays
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 4, height: 10)
                    .offset(y: -31)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
        }
        .rotationEffect(.degrees(rotation))
        .position(x: UIScreen.main.bounds.width - 60, y: 102)
        .shadow(color: .yellow.opacity(0.3), radius: 10)
    }
}

struct BirdView: View {
    @State private var flapWings = false
    
    var body: some View {
        Path { path in
            // Left wing
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 10, y: 0),
                control: CGPoint(x: 5, y: flapWings ? -5 : 5)
            )
            
            // Right wing
            path.move(to: CGPoint(x: 10, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 20, y: 0),
                control: CGPoint(x: 15, y: flapWings ? -5 : 5)
            )
        }
        .stroke(Color.black, lineWidth: 2)
        .frame(width: 20, height: 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever()) {
                flapWings.toggle()
            }
        }
    }
}

// Update the DynamicBackground with more nature-inspired colors
struct DynamicBackground: View {
    @Environment(\.colorScheme) var colorScheme
    let isForestTheme: Bool
    
    var gradientColors: [Color] {
        if isForestTheme {
            return [
                Color(red: 0.1, green: 0.3, blue: 0.1),  // Dark forest green
                Color(red: 0.15, green: 0.35, blue: 0.15),  // Medium forest green
                Color(red: 0.2, green: 0.4, blue: 0.2)   // Lighter forest green
            ]
        } else {
            return [
                Color(red: 0.2, green: 0.6, blue: 0.9),  // Ocean blue
                Color(red: 0.4, green: 0.7, blue: 0.9),  // Sky blue
                Color(red: 0.5, green: 0.8, blue: 1.0)   // Light azure
            ]
        }
    }
    
    var body: some View {
        ZStack {
            // Base gradient with higher opacity for forest theme
            LinearGradient(
                colors: gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(isForestTheme ? 0.9 : 0.7)  // Higher opacity for forest theme
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// Add a floating leaf animation
struct FloatingLeaf: View {
    @State private var position: CGPoint
    @State private var rotation: Double = 0
    
    init(initialPosition: CGPoint) {
        _position = State(initialValue: initialPosition)
    }
    
    var body: some View {
        Image(systemName: "leaf.fill")
            .foregroundColor(.green.opacity(0.4))
            .frame(width: 20, height: 20)
            .position(x: position.x, y: position.y)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: Double.random(in: 8...15))
                        .repeatForever(autoreverses: false)
                ) {
                    position.y = -50
                    rotation = 360
                }
            }
    }
}

// Add subtle water ripples
struct WaterRipples: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.3
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(Color.white.opacity(opacity), lineWidth: 1)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(
                        Animation
                            .easeInOut(duration: 4)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 1.5),
                        value: scale
                    )
            }
        }
        .onAppear {
            scale = 2.0
            opacity = 0
        }
    }
}

// Add this new view for clouds
struct CloudsView: View {
    @State private var cloudOffset1: CGFloat = -200
    @State private var cloudOffset2: CGFloat = UIScreen.main.bounds.width
    
    var body: some View {
        ZStack {
            // Cloud 1 - increased y offset from 120 to 50
            CloudShape()
                .fill(Color.white.opacity(0.8))
                .frame(width: 120, height: 60)
                .offset(x: cloudOffset1, y: 50)  // Changed from y: 120 to y: 50
                .onAppear {
                    withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                        cloudOffset1 = UIScreen.main.bounds.width + 200
                    }
                }
            
            // Cloud 2 - increased y offset from 180 to 90
            CloudShape()
                .fill(Color.white.opacity(0.6))
                .frame(width: 100, height: 50)
                .offset(x: cloudOffset2, y: 90)  // Changed from y: 180 to y: 90
                .onAppear {
                    withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
                        cloudOffset2 = -200
                    }
                }
        }
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Draw a cloud shape using multiple circles
        path.addEllipse(in: CGRect(x: rect.midX - 25, y: rect.midY - 15, width: 50, height: 30))
        path.addEllipse(in: CGRect(x: rect.midX - 40, y: rect.midY - 10, width: 40, height: 25))
        path.addEllipse(in: CGRect(x: rect.midX, y: rect.midY - 10, width: 40, height: 25))
        
        return path
    }
}

// Add this new view for game stats
struct GameStatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// Now let's update the CalendarView to show streaks and rewards
struct CalendarView: View {
    @ObservedObject var gameState: GameState
    @State private var selectedDate = Date()
    @State private var showAddActivitySheet = false
    @State private var inputImage: UIImage?
    @State private var activityDescription: String = ""
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.7), Color.blue.opacity(0.5)]),
                          startPoint: .top,
                          endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Top Stats Section
                    VStack(spacing: 15) {
                        // Coins and Streak Row
                        HStack {
                            // Streak Counter
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 24))
                                Text("\(gameState.currentStreak)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Day Streak")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(15)
                            
                            Spacer()
                            
                            // Updated Coins display with bounce animation
                            CoinView(coins: gameState.coins)
                                .scaleEffect(gameState.showBonusAlert ? 1.1 : 1.0)
                                .animation(.interpolatingSpring(stiffness: 170, damping: 15),
                                          value: gameState.showBonusAlert)
                        }
                        
                        // Streak Progress
                        VStack(spacing: 10) {
                            Text("7-Day Challenge Progress")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            StreakProgressView(currentStreak: gameState.currentStreak)
                            
                            if gameState.currentStreak < 7 {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("Complete 7 days for \(gameState.bonusCoinsForStreak) bonus coins!")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green.opacity(0.3))
                                .cornerRadius(10)
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)
                    
                    // Calendar Section
                    VStack(spacing: 15) {
                        Text("Activity Calendar")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    .padding()
                    
                    // Add Activity Button
                    if Calendar.current.isDateInToday(selectedDate) {
                        Button(action: {
                            showAddActivitySheet = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20))
                                Text("Add Today's Nature Activity")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    }
                    
                    // Activities Display
                    if let activity = gameState.getNatureActivity(for: selectedDate) {
                        LazyVStack(spacing: 15) {
                            ForEach(activity.entries.sorted(by: { $0.timestamp > $1.timestamp })) { entry in
                                ActivityEntryView(entry: entry)
                            }
                        }
                        .padding(.horizontal)
                    } else if !Calendar.current.isDateInToday(selectedDate) {
                        EmptyActivityView()
                    }
                }
                .padding(.vertical)
            }
            
            // Bonus Alert
            if gameState.showBonusAlert {
                BonusAlertView()
            }
        }
        .sheet(isPresented: $showAddActivitySheet) {
            AddActivitySheet(
                showSheet: $showAddActivitySheet,
                inputImage: $inputImage,
                activityDescription: $activityDescription,
                gameState: gameState,
                selectedDate: selectedDate
            )
        }
    }
}

// Add this new view for empty state
struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.7))
            
            Text("No activities recorded")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Add activities to earn coins and build your streak!")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(25)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.3))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// Add this new view for bonus alert
struct BonusAlertView: View {
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 15) {
                Image(systemName: "star.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.yellow)
                
                VStack(spacing: 5) {
                    Text("7-Day Streak Bonus!")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("+100 Coins Earned!")
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                }
                
                Image(systemName: "star.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.yellow)
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(25)
            .shadow(radius: 10)
            .padding(.bottom, 30)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct ActivityEntryView: View {
    let entry: ActivityEntry
    
    var body: some View {
        VStack(spacing: 10) {
            if let uiImage = UIImage(data: entry.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.description)
                    .foregroundColor(.white)
                
                Text(entry.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.2))
            .cornerRadius(10)
        }
        .padding(.vertical, 5)
    }
}

struct AddActivitySheet: View {
    @Binding var showSheet: Bool
    @Binding var inputImage: UIImage?
    @Binding var activityDescription: String
    @ObservedObject var gameState: GameState
    let selectedDate: Date
    
    @State private var showImagePicker = false
    @State private var showCoinReward = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if let image = inputImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .overlay(
                                Button(action: {
                                    inputImage = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .padding(8),
                                alignment: .topTrailing
                            )
                    } else {
                        Button(action: {
                            showImagePicker = true
                        }) {
                            VStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.largeTitle)
                                Text("Add Photo")
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                        }
                    }
                    
                    TextField("Describe your nature activity...", text: $activityDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Spacer()
                }
                
                // Coin reward animation overlay
                if showCoinReward {
                    VStack {
                        Image(systemName: "coins.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        Text("+\(gameState.coinsPerActivity)")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showCoinReward)
            .navigationTitle("Add Nature Activity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    inputImage = nil
                    activityDescription = ""
                    showSheet = false
                },
                trailing: Button("Save") {
                    saveActivity()
                }
                .disabled(inputImage == nil || activityDescription.isEmpty)
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage)
            }
        }
    }
    
    private func saveActivity() {
        if let image = inputImage,
           let imageData = image.jpegData(compressionQuality: 0.7) {
            let entry = ActivityEntry(
                imageData: imageData,
                description: activityDescription
            )
            
            // Show coin reward animation
            withAnimation {
                showCoinReward = true
            }
            
            // Add activity and reward after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                gameState.addNatureActivity(entry, for: selectedDate)
                
                // Reset the form
                inputImage = nil
                activityDescription = ""
                showCoinReward = false
                showSheet = false
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Add this struct to store nature activities
struct NatureActivity: Identifiable, Codable {
    let id: UUID
    let date: Date
    var entries: [ActivityEntry]
    
    init(id: UUID = UUID(), date: Date, entries: [ActivityEntry] = []) {
        self.id = id
        self.date = date
        self.entries = entries
    }
}

// New struct to store individual activity entries
struct ActivityEntry: Identifiable, Codable {
    let id: UUID
    let imageData: Data
    let description: String
    let timestamp: Date
    
    init(id: UUID = UUID(), imageData: Data, description: String, timestamp: Date = Date()) {
        self.id = id
        self.imageData = imageData
        self.description = description
        self.timestamp = timestamp
    }
}

// Add this new view for the forest background
struct ForestView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: -20) {
                ForEach(0..<8) { index in
                    Image(systemName: "tree.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 80)
                        .foregroundColor(Color.green.opacity(0.8))
                        .offset(y: index % 2 == 0 ? 0 : 10)
                }
            }
            .frame(height: 60)
            .padding(.bottom, -10)
        }
    }
}

// Add this new view for the flying carpet
struct FlyingCarpetView: View {
    @Binding var position: CGFloat
    @Binding var positionY: CGFloat
    
    var body: some View {
        ZStack {
            // Carpet base with floating animation
            Rectangle()
                .frame(width: 60, height: 20)
                .foregroundColor(Color.purple.opacity(0.8))
                .cornerRadius(10)
                .overlay(
                    Rectangle()
                        .frame(width: 50, height: 16)
                        .foregroundColor(Color.purple.opacity(0.4))
                        .cornerRadius(8)
                )
                .overlay(
                    HStack(spacing: 4) {
                        ForEach(0..<5) { _ in
                            Rectangle()
                                .frame(width: 2, height: 12)
                                .foregroundColor(Color.yellow.opacity(0.6))
                        }
                    }
                )
            
            // Character on carpet
            Image(systemName: "person.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.yellow)
                .offset(y: -15)
        }
        .position(x: position, y: positionY)
        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

// Add these new views for different level appearances
struct LockedLevelView: View {
    let level: Int
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.gray.opacity(0.7), .gray.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    )
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            
            Text("Level \(level)")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text("Locked")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Image(systemName: "coins.fill")
                .font(.system(size: 24))
                .foregroundColor(.yellow)
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
        }
        .frame(width: 230, height: 230)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct FirstLevelView: View {
    let level: Int
    let isForestTheme: Bool
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Level number with glowing effect
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                isForestTheme ? .green : .blue,
                                isForestTheme ? .green.opacity(0.7) : .blue.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                Text("\(level)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            
            // Level description with improved styling
            Text(description)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
            
            // Theme icon
            Image(systemName: isForestTheme ? "leaf.fill" : "drop.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.9))
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
        }
        .frame(width: 230, height: 230)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            isForestTheme ? Color(red: 0.2, green: 0.4, blue: 0.2) : Color(red: 0.2, green: 0.3, blue: 0.5),
                            isForestTheme ? Color(red: 0.1, green: 0.3, blue: 0.1) : Color(red: 0.1, green: 0.2, blue: 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct ForestLevelView: View {
    let level: Int
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .green.opacity(0.5), radius: 10)
                
                Text("\(level)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            
            Text(description)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
            
            Image(systemName: "leaf.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.9))
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
        }
        .frame(width: 230, height: 230)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.4, blue: 0.2),
                            Color(red: 0.1, green: 0.3, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct RiverLevelView: View {
    let level: Int
    let description: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .blue.opacity(0.5), radius: 10)
                
                Text("\(level)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            
            Text(description)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
            
            Image(systemName: "drop.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.9))
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                )
        }
        .frame(width: 230, height: 230)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            backgroundColor.opacity(0.8),
                            backgroundColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// Update CoinView with a more attractive design
struct CoinView: View {
    let coins: Int
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        HStack(spacing: 8) {
            // Coin stack icon
            ZStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                
                Image(systemName: "dollarsign")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .bold))
            }
            
            // Coin amount with background
            Text("\(coins)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2)
                .frame(minWidth: 50)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.2),
                        Color(red: 0.3, green: 0.3, blue: 0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle shine effect
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(
                    gradient: Gradient(colors: [
                        .white.opacity(0.5),
                        .white.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}

// Add a streak progress view
struct StreakProgressView: View {
    let currentStreak: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Streak Progress")
                .font(.caption)
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                ForEach(0..<7) { index in
                    Circle()
                        .fill(index < currentStreak ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
            }
            
            if currentStreak < 7 {
                Text("\(7 - currentStreak) more days for bonus!")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }
}

// Add this new custom view for locked level popup
struct LockLevelPopup: View {
    @Binding var isPresented: Bool
    let level: Int
    let currentCoins: Int
    let requiredCoins: Int
    let onUnlock: () -> Void
    @Binding var showInsufficientCoins: Bool
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }
            
            // Popup content
            VStack(spacing: 20) {
                // Top decoration with lock icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }
                .offset(y: -40)
                .padding(.bottom, -40)
                
                Text("Level \(level) Locked")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Coins display
                HStack(spacing: 15) {
                    // Current coins
                    VStack {
                        Text("Your Coins")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        HStack(spacing: 5) {
                            Image(systemName: "coins.fill")
                                .foregroundColor(.yellow)
                            Text("\(currentCoins)")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Required coins
                    VStack {
                        Text("Required")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        HStack(spacing: 5) {
                            Image(systemName: "coins.fill")
                                .foregroundColor(.yellow)
                            Text("\(requiredCoins)")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if currentCoins >= requiredCoins {
                            onUnlock()
                            withAnimation {
                                isPresented = false
                            }
                        } else {
                            showInsufficientCoins = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("Unlock Level")
                            Text("(\(requiredCoins) coins)")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                }
                .padding(.top)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.3),
                                Color(red: 0.2, green: 0.2, blue: 0.4)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 20)
            .padding(30)
            .transition(.scale.combined(with: .opacity))
        }
    }
}
