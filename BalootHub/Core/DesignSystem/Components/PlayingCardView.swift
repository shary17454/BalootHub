import SwiftUI
import BalootEngine

// MARK: - ألوان الأنماط

extension TableFeltStyle {
    /// تدرّج سطح الطاولة. ألوان ثابتة لا تتبع الوضع الفاتح/الداكن لأنها "لبس طاولة"
    /// مقصود بلونه، تمامًا كجوخ الطاولة الحقيقي.
    var gradient: LinearGradient {
        LinearGradient(
            colors: feltColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var feltColors: [Color] {
        switch self {
        case .emerald: [Color(red: 0.06, green: 0.32, blue: 0.24), Color(red: 0.03, green: 0.21, blue: 0.16)]
        case .sand: [Color(red: 0.78, green: 0.68, blue: 0.50), Color(red: 0.62, green: 0.52, blue: 0.36)]
        case .maroon: [Color(red: 0.36, green: 0.11, blue: 0.14), Color(red: 0.22, green: 0.06, blue: 0.09)]
        case .midnight: [Color(red: 0.10, green: 0.14, blue: 0.28), Color(red: 0.05, green: 0.07, blue: 0.16)]
        }
    }

    /// لون النص المقروء فوق هذا اللبس.
    var contentColor: Color {
        self == .sand ? Color(red: 0.16, green: 0.12, blue: 0.06) : .white
    }
}

extension TableThemeStyle {
    /// لون الهوية الذي يصبغ الإبرازات داخل شاشة اللعب.
    var accentColor: Color {
        switch self {
        case .baloot: AppColor.primary
        case .desert: Color(red: 0.76, green: 0.56, blue: 0.20)
        case .coffee: Color(red: 0.48, green: 0.30, blue: 0.16)
        case .pearl: Color(red: 0.24, green: 0.52, blue: 0.70)
        }
    }
}

extension CardFaceStyle {
    /// نص القيمة المعروض على الورقة.
    ///
    /// النمط التراثي يستبدل الحروف اللاتينية بأرقام عربية-هندية وبأوائل الأسماء
    /// المتداولة في المجالس (أكه · شيخ · بنت · ولد). مشتركة بين شاشة اللعب وشريط
    /// Replay حتى لا يختلف شكل الورقة بين الشاشتين.
    func label(for rank: Rank) -> String {
        guard usesArabicIndicDigits else { return rank.shortLabel }
        switch rank {
        case .seven: return "٧"
        case .eight: return "٨"
        case .nine: return "٩"
        case .ten: return "١٠"
        case .jack: return "و"
        case .queen: return "ب"
        case .king: return "ش"
        case .ace: return "أ"
        }
    }
}

extension CardBackStyle {
    var backColors: [Color] {
        switch self {
        case .sadu: [Color(red: 0.55, green: 0.13, blue: 0.13), Color(red: 0.30, green: 0.07, blue: 0.07)]
        case .diamondGrid: [Color(red: 0.16, green: 0.30, blue: 0.52), Color(red: 0.08, green: 0.17, blue: 0.34)]
        case .night: [Color(red: 0.12, green: 0.13, blue: 0.22), Color(red: 0.04, green: 0.05, blue: 0.10)]
        case .palm: [Color(red: 0.10, green: 0.34, blue: 0.24), Color(red: 0.04, green: 0.18, blue: 0.13)]
        }
    }
}

extension AvatarStyle {
    /// رمز المقعد حسب ترتيبه (0..3) في النمط التراثي.
    static func heritageSymbol(seatIndex: Int) -> String {
        let symbols = ["bird.fill", "cup.and.saucer.fill", "tree.fill", "tent.fill"]
        return symbols[((seatIndex % symbols.count) + symbols.count) % symbols.count]
    }

    static func geometricSymbol(seatIndex: Int) -> String {
        let symbols = ["circle.fill", "square.fill", "triangle.fill", "diamond.fill"]
        return symbols[((seatIndex % symbols.count) + symbols.count) % symbols.count]
    }

    static func geometricColor(seatIndex: Int) -> Color {
        let colors: [Color] = [
            Color(red: 0.20, green: 0.52, blue: 0.46),
            Color(red: 0.72, green: 0.52, blue: 0.16),
            Color(red: 0.36, green: 0.36, blue: 0.66),
            Color(red: 0.66, green: 0.30, blue: 0.30)
        ]
        return colors[((seatIndex % colors.count) + colors.count) % colors.count]
    }
}

// MARK: - وجه الورقة

/// رسم وجه ورقة واحدة بالنمط المختار.
///
/// نُقل هنا من داخل شاشة اللعب ليُعاد استخدامه في المعاينة داخل شاشة التخصيص
/// وفي Replay وSandbox بدل تكرار الرسم في كل شاشة.
struct PlayingCardFaceView: View {
    let card: PlayingCard
    var style: CardFaceStyle = .classic
    var isHighlighted: Bool = false

    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 46
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 64

    private var isRed: Bool { card.suit.isRed }

    var body: some View {
        content
            .foregroundStyle(isRed ? AppColor.danger : AppColor.textPrimary)
            .minimumScaleFactor(0.55)
            .frame(width: cardWidth, height: cardHeight)
            .background(AppColor.surfaceElevated, in: RoundedRectangle(cornerRadius: AppRadius.small))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .stroke(isHighlighted ? AppColor.accent : AppColor.border, lineWidth: isHighlighted ? 2 : 1)
            )
            .accessibilityLabel(card.accessibilityName)
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .classic:
            // ورقة لعب حقيقية: فهرس في الزاوية (قيمة فوق رمز) ورمز أكبر في المنتصف.
            // كان النمط سابقًا قيمة ورمزًا في المنتصف فقط، فبدت الورقة رقعةً لا ورقة،
            // ويصعب تمييزها حين تتجاور الأوراق في اليد.
            ZStack {
                Image(systemName: symbolName)
                    .font(.system(size: 20))
                    .opacity(0.9)
                VStack {
                    HStack {
                        VStack(spacing: -1) {
                            Text(rankLabel)
                                .font(.system(size: 11, design: .rounded).weight(.heavy))
                            Image(systemName: symbolName)
                                .font(.system(size: 7))
                        }
                        Spacer(minLength: 0)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 3)
                .padding(.top, 3)
            }
        case .bold:
            VStack(spacing: 0) {
                Text(rankLabel)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                Image(systemName: symbolName)
                    .font(.caption2)
            }
        case .heritage:
            VStack(spacing: 2) {
                Text(rankLabel)
                    .font(.system(.title3, design: .serif).weight(.semibold))
                Image(systemName: symbolName)
                    .font(.caption2)
            }
        case .minimal:
            VStack(alignment: .leading, spacing: 1) {
                Text(rankLabel)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Image(systemName: symbolName)
                    .font(.caption2)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xxs)
            .padding(.top, AppSpacing.xxs)
        }
    }

    private var rankLabel: String { style.label(for: card.rank) }

    private var symbolName: String {
        switch card.suit {
        case .hearts: "suit.heart.fill"
        case .diamonds: "suit.diamond.fill"
        case .clubs: "suit.club.fill"
        case .spades: "suit.spade.fill"
        }
    }
}

// MARK: - ظهر الورقة

/// رسم ظهر ورقة مخفية بالنمط المختار — يُستخدم لأوراق الخصوم وشاشة تمرير الجهاز.
struct PlayingCardBackView: View {
    var style: CardBackStyle = .sadu

    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 46
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 64

    var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.small)
            .fill(
                LinearGradient(colors: style.backColors, startPoint: .top, endPoint: .bottom)
            )
            .overlay(pattern.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.small)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .frame(width: cardWidth, height: cardHeight)
            .accessibilityLabel("ورقة مخفية")
    }

    @ViewBuilder
    private var pattern: some View {
        switch style {
        case .sadu:
            VStack(spacing: 2) {
                ForEach(0..<7, id: \.self) { row in
                    Rectangle()
                        .fill(Color.white.opacity(row.isMultiple(of: 2) ? 0.6 : 0.2))
                        .frame(height: row.isMultiple(of: 2) ? 2 : 4)
                }
            }
            .padding(.horizontal, 5)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
        case .diamondGrid:
            GeometryReader { proxy in
                let step = max(proxy.size.width / 3, 1)
                Path { path in
                    var y: CGFloat = 0
                    while y < proxy.size.height + step {
                        var x: CGFloat = 0
                        while x < proxy.size.width + step {
                            path.move(to: CGPoint(x: x, y: y - step / 2))
                            path.addLine(to: CGPoint(x: x + step / 2, y: y))
                            path.addLine(to: CGPoint(x: x, y: y + step / 2))
                            path.addLine(to: CGPoint(x: x - step / 2, y: y))
                            path.closeSubpath()
                            x += step
                        }
                        y += step
                    }
                }
                .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
        case .night:
            Image(systemName: "sparkle")
                .font(.system(size: 16))
                .foregroundStyle(Color.white.opacity(0.7))
        case .palm:
            Image(systemName: "leaf.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.white.opacity(0.7))
                .rotationEffect(.degrees(-20))
        }
    }
}

// MARK: - سطح الطاولة والخلفية

/// سطح الطاولة الملوّن الذي تُلعب فوقه الأكلة.
struct TableFeltSurface: View {
    var style: TableFeltStyle = .emerald

    var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.large)
            .fill(style.gradient)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.large)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .accessibilityHidden(true)
    }
}

/// خلفية شاشة اللعب خلف الطاولة.
struct TableBackdrop: View {
    var style: TableBackdropStyle = .plain
    var theme: TableThemeStyle = .baloot

    /// مواضع ثابتة للنجوم — قيم عشوائية وقت الرسم كانت ستتحرّك مع كل إعادة رسم.
    private static let starPositions: [CGPoint] = [
        CGPoint(x: 0.12, y: 0.08), CGPoint(x: 0.34, y: 0.17), CGPoint(x: 0.61, y: 0.06),
        CGPoint(x: 0.82, y: 0.21), CGPoint(x: 0.21, y: 0.42), CGPoint(x: 0.90, y: 0.55),
        CGPoint(x: 0.08, y: 0.71), CGPoint(x: 0.47, y: 0.88), CGPoint(x: 0.73, y: 0.79)
    ]

    var body: some View {
        Group {
            switch style {
            case .plain:
                AppColor.background
            case .glow:
                AppColor.background.overlay(
                    RadialGradient(
                        colors: [theme.accentColor.opacity(0.20), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 320
                    )
                )
            case .saduFrame:
                AppColor.background.overlay(alignment: .leading) { saduStrip }
                    .overlay(alignment: .trailing) { saduStrip }
            case .stars:
                AppColor.background.overlay { starField }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var saduStrip: some View {
        VStack(spacing: 3) {
            ForEach(0..<40, id: \.self) { row in
                Rectangle()
                    .fill(theme.accentColor.opacity(row.isMultiple(of: 2) ? 0.28 : 0.10))
                    .frame(height: row.isMultiple(of: 2) ? 3 : 6)
            }
        }
        .frame(width: 10)
    }

    private var starField: some View {
        GeometryReader { proxy in
            ForEach(Array(Self.starPositions.enumerated()), id: \.offset) { index, point in
                Circle()
                    .fill(theme.accentColor.opacity(index.isMultiple(of: 2) ? 0.30 : 0.16))
                    .frame(width: index.isMultiple(of: 3) ? 4 : 2.5)
                    .position(x: point.x * proxy.size.width, y: point.y * proxy.size.height)
            }
        }
    }
}

// MARK: - صورة اللاعب

/// صورة/رمز اللاعب في المقعد حسب النمط المختار.
struct SeatAvatarView: View {
    let name: String
    let seatIndex: Int
    var style: AvatarStyle = .person
    var theme: TableThemeStyle = .baloot
    var isCurrentTurn: Bool = false

    private var fillColor: Color {
        if isCurrentTurn { return theme.accentColor }
        return style == .geometric ? AvatarStyle.geometricColor(seatIndex: seatIndex).opacity(0.22) : AppColor.surface
    }

    private var foreground: Color {
        isCurrentTurn ? .white : AppColor.textSecondary
    }

    var body: some View {
        ZStack {
            Circle().fill(fillColor).frame(width: 44, height: 44)
            switch style {
            case .person:
                Image(systemName: "person.fill").foregroundStyle(foreground)
            case .initials:
                Text(initial)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(foreground)
            case .heritage:
                Image(systemName: AvatarStyle.heritageSymbol(seatIndex: seatIndex))
                    .foregroundStyle(foreground)
            case .geometric:
                Image(systemName: AvatarStyle.geometricSymbol(seatIndex: seatIndex))
                    .foregroundStyle(isCurrentTurn ? .white : AvatarStyle.geometricColor(seatIndex: seatIndex))
            }
        }
        .accessibilityHidden(true)
    }

    /// أول حرف فعلي من الاسم. الاسم قد يبدأ بمسافة أو يكون فارغًا بعد تعديل المستخدم.
    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "؟" : String(trimmed.prefix(1))
    }
}

#Preview("وجه الورقة") {
    HStack {
        ForEach(CardFaceStyle.allCases) { style in
            PlayingCardFaceView(card: PlayingCard(suit: .hearts, rank: .ten), style: style)
        }
    }
    .padding()
}

#Preview("ظهر الورقة") {
    HStack {
        ForEach(CardBackStyle.allCases) { style in
            PlayingCardBackView(style: style)
        }
    }
    .padding()
}
