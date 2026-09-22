import SwiftUI

/// An explanatory animation only. It has no repository, persistence or notification access.
struct DemoWorkflowAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var running = true
    @State private var start = Date.now
    @State private var offset: Double = 0
    private let duration: Double = 25
    private let captions = [
        "Read the receipt and review the items.",
        "The receipt splits into an expense and purchased items.",
        "Bought items leave shopping; ingredients reach the pantry.",
        "Pack dates stay with the food you store.",
        "Your pantry becomes the starting point for tomorrow’s meals."
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Watch your home connect").font(.headline).accessibilityAddTraits(.isHeader)
                Spacer()
                Text("5× slow").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !running || reduceMotion || scenePhase != .active)) { context in
                let seconds = elapsed(context.date).truncatingRemainder(dividingBy: duration)
                let progress = seconds / duration
                VStack(alignment: .leading, spacing: 12) {
                    Canvas { graphics, size in draw(in: &graphics, size: size, progress: progress) }
                        .frame(height: 440).background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                        .accessibilityHidden(true)
                    Text(captions[min(4, Int(progress * 5))]).font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("demo.animationCaption")
                }
            }
            HStack(spacing: 24) {
                Button(running && !reduceMotion ? "Pause" : "Play", systemImage: running && !reduceMotion ? "pause.fill" : "play.fill") {
                    if running { offset = elapsed(.now); running = false }
                    else { start = .now; running = true }
                }.disabled(reduceMotion).frame(minHeight: 44).accessibilityIdentifier("demo.play")
                Button("Next scene", systemImage: "forward.end") {
                    offset = (floor(elapsed(.now) / 5) + 1) * 5; start = .now; running = false
                }.frame(minHeight: 44).accessibilityIdentifier("demo.next")
            }.font(.subheadline)
            Text(reduceMotion ? "Reduce Motion: explore the five still scenes with Next scene." : "Continuous 25-second illustration · pause anytime. Sample values illustrate the flow; your actual demo records are below.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .onChange(of: scenePhase) { _, value in if value != .active { offset = elapsed(.now); running = false } }
        .onChange(of: reduceMotion) { _, value in if value { offset = 0; running = false } }
        .onDisappear { offset = elapsed(.now); running = false }
    }
    private func elapsed(_ date: Date) -> Double { offset + (running && !reduceMotion ? max(0, date.timeIntervalSince(start)) : 0) }
    private func ramp(_ p: Double, _ from: Double, _ to: Double) -> Double {
        let t = min(1, max(0, (p - from) / (to - from)))
        return t * t * (3 - 2 * t)
    }
    private func draw(in context: inout GraphicsContext, size: CGSize, progress p: Double) {
        let center = CGPoint(x: size.width / 2, y: 62)
        let expense = CGPoint(x: size.width * 0.19, y: 215)
        let shopping = CGPoint(x: size.width * 0.5, y: 215)
        let pantry = CGPoint(x: size.width * 0.81, y: 215)
        let meal = CGPoint(x: size.width / 2, y: 365)
        let purple = ExpenseTheme.accent, green = ShoppingTheme.accent, rust = InventoryTheme.accent
        func label(_ text: String, _ point: CGPoint, color: Color = .primary, size: CGFloat = 12) {
            context.draw(Text(text).font(.system(size: size, weight: .semibold)).foregroundColor(color), at: point)
        }
        func line(_ a: CGPoint, _ b: CGPoint, color: Color) {
            var path = Path(); path.move(to: a)
            path.addCurve(to: b, control1: CGPoint(x: a.x, y: (a.y+b.y)/2), control2: CGPoint(x: b.x, y: (a.y+b.y)/2))
            context.stroke(path, with: .color(color.opacity(0.18)), style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
        }
        func travel(_ a: CGPoint, _ b: CGPoint, t: Double, symbol: String, color: Color) {
            guard t > 0 && t < 1 else { return }
            let point = CGPoint(x: a.x + (b.x-a.x)*t, y: a.y + (b.y-a.y)*t)
            context.fill(Path(ellipseIn: CGRect(x: point.x-14,y: point.y-14,width:28,height:28)), with: .color(color.opacity(0.14)))
            context.draw(Text(Image(systemName: symbol)).font(.system(size: 17, weight: .semibold)).foregroundColor(color), at: point)
        }
        func tile(_ point: CGPoint, color: Color, active: Double) {
            let rect = CGRect(x: point.x-40, y: point.y-42, width:80,height:84)
            context.fill(Path(roundedRect: rect, cornerRadius: 18), with: .color(color.opacity(0.06+active*0.1)))
            context.stroke(Path(roundedRect: rect.insetBy(dx: 1,dy: 1), cornerRadius: 17), with: .color(color.opacity(0.15+active*0.3)), lineWidth: 1)
        }
        // Receipt scan: real paper shape, written lines and a moving scan beam.
        let paper = CGRect(x:center.x-29,y:center.y-37,width:58,height:74)
        context.fill(Path(roundedRect: paper, cornerRadius: 6), with: .color(purple.opacity(0.08)))
        for row in 0..<5 {
            let y = paper.minY + 15 + CGFloat(row)*10
            var path=Path();path.move(to:CGPoint(x:paper.minX+10,y:y));path.addLine(to:CGPoint(x:paper.maxX-10,y:y))
            context.stroke(path,with:.color(purple.opacity(row==4 ? 0.7:0.3)),lineWidth:row==4 ? 3:2)
        }
        if p < 0.2 {
            let y=paper.minY+74*ramp(p,0,0.2)
            context.fill(Path(CGRect(x:paper.minX-7,y:y,width:72,height:3)),with:.color(green))
        }
        label("Receipt", CGPoint(x:center.x,y:112),color:purple)
        for (point,color) in [(expense,purple),(shopping,green),(pantry,rust)] {
            line(CGPoint(x:center.x,y:124),CGPoint(x:point.x,y:169),color:color)
        }
        tile(expense,color:purple,active:ramp(p,0.24,0.4))
        label("$16.00",CGPoint(x:expense.x,y:expense.y-13),color:purple,size:16)
        for index in 0..<3 {
            let height=CGFloat([14,25,19][index])*ramp(p,0.27,0.4)
            context.fill(Path(roundedRect:CGRect(x:expense.x-23+CGFloat(index)*17,y:expense.y+25-height,width:11,height:height),cornerRadius:3),with:.color(purple.opacity(0.65)))
        }
        label("Expenses",CGPoint(x:expense.x,y:272),color:purple)
        tile(shopping,color:green,active:ramp(p,0.36,0.57))
        for index in 0..<3 {
            let done=ramp(p,0.4+Double(index)*0.035,0.48+Double(index)*0.035)
            let y=shopping.y-23+CGFloat(index)*21
            let rect=CGRect(x:shopping.x-24,y:y,width:12,height:12)
            context.stroke(Path(roundedRect:rect,cornerRadius:3),with:.color(green.opacity(1-done*0.7)),lineWidth:1.5)
            if done>0.5 { label("✓",CGPoint(x:shopping.x-18,y:y+6),color:green,size:13) }
            context.fill(Path(CGRect(x:shopping.x-3,y:y+5,width:27*(1-done),height:3)),with:.color(green.opacity(0.6)))
        }
        label(p>0.58 ? "Bought ✓":"Shopping",CGPoint(x:shopping.x,y:272),color:green)
        tile(pantry,color:rust,active:ramp(p,0.47,0.65))
        for index in 0..<3 {
            let arrive=ramp(p,0.46+Double(index)*0.04,0.57+Double(index)*0.04)
            var jar=context;jar.opacity=arrive
            let rect=CGRect(x:pantry.x-28+CGFloat(index)*19,y:pantry.y-12-(1-arrive)*28,width:16,height:35)
            jar.fill(Path(roundedRect:rect,cornerRadius:4),with:.color([Color.orange,Color.green,rust][index].opacity(0.5)))
            jar.fill(Path(CGRect(x:rect.minX,y:rect.minY-3,width:16,height:4)),with:.color(rust))
        }
        context.fill(Path(CGRect(x:pantry.x-29,y:pantry.y+27,width:58,height:3)),with:.color(rust.opacity(0.6)))
        label("Pantry",CGPoint(x:pantry.x,y:272),color:rust)
        if p>0.64 { label("Pack dates",CGPoint(x:pantry.x,y:293),color:rust,size:10) }
        for (target,color,symbol,from,to) in [(expense,purple,"dollarsign",0.2,0.36),(shopping,green,"checkmark",0.28,0.47),(pantry,rust,"carrot",0.36,0.58)] {
            travel(center,target,t:ramp(p,from,to),symbol:symbol,color:color)
        }
        line(CGPoint(x:pantry.x,y:304),CGPoint(x:meal.x,y:329),color:rust)
        travel(CGPoint(x:pantry.x,y:304),CGPoint(x:meal.x,y:345),t:ramp(p,0.7,0.87),symbol:"carrot.fill",color:rust)
        let ready=ramp(p,0.78,0.94)
        context.fill(Path(ellipseIn:CGRect(x:meal.x-44,y:meal.y-33,width:88,height:66)),with:.color(Color.orange.opacity(0.06+ready*0.12)))
        context.stroke(Path(ellipseIn:CGRect(x:meal.x-33,y:meal.y-25,width:66,height:50)),with:.color(Color.orange.opacity(0.35)),lineWidth:2)
        for index in 0..<5 {
            let angle=Double(index)*1.256+ready*0.6
            let point=CGPoint(x:meal.x+cos(angle)*19,y:meal.y+sin(angle)*13)
            context.fill(Path(ellipseIn:CGRect(x:point.x-5,y:point.y-5,width:10*ready,height:10*ready)),with:.color(index%2==0 ? green:Color.orange))
        }
        label("Tomorrow’s meals",CGPoint(x:meal.x,y:416),color:.primary,size:13)
    }
}
