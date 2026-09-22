import SwiftUI

struct MealPlansView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var day: Date
    @State private var adding = false
    init(initialDay: Date) { _day = State(initialValue: initialDay) }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("At your table.").font(AppTheme.displayTitle)
                        Text("Your meals, one day at a time.").foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "fork.knife.circle.fill").font(.system(size: 52)).foregroundStyle(InventoryTheme.accent).accessibilityHidden(true)
                }
                NavigationLink { WeeklyMealPlannerView() } label: { Label("Plan the week", systemImage: "calendar") }.frame(minHeight: 44).accessibilityIdentifier("meals.week")
                DatePicker("Your day", selection: $day, displayedComponents: .date)
                    .padding(18).background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                let meals = repository.meals(on: day)
                if meals.isEmpty {
                    ContentUnavailableView("Nothing planned yet", systemImage: "sun.horizon", description: Text("Add a meal for this day, or find ideas from your pantry."))
                    Button("Add a meal", systemImage: "plus") { adding = true }.buttonStyle(.bordered)
                    NavigationLink("Find meal ideas") { MealIdeasView() }.frame(minHeight: 44)
                }
                ForEach(meals) { meal in
                    NavigationLink { MealCookingView(meal: meal) } label: {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Label(meal.mealType, systemImage: "sun.horizon").font(.subheadline)
                                Spacer()
                                if meal.cookedAt != nil { Label("Cooked", systemImage: "checkmark.circle.fill").font(.caption) }
                            }.foregroundStyle(InventoryTheme.accent)
                            Text(meal.title).font(AppTheme.sectionTitle).foregroundStyle(.primary)
                            Text("\(meal.servings ?? 2) servings · \((meal.ingredientNames ?? []).count) ingredients").font(.subheadline).foregroundStyle(.secondary)
                            HStack { Text("Ingredients & shopping"); Spacer(); Image(systemName: "arrow.right") }.font(.subheadline.weight(.semibold)).foregroundStyle(InventoryTheme.accent)
                        }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                            .background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 18)).contentShape(Rectangle())
                    }.buttonStyle(.plain).entryActions(.editing(meal))
                }
            }.padding(20).frame(maxWidth: 800).frame(maxWidth: .infinity)
        }.background(InventoryTheme.canvas).tint(InventoryTheme.accent)
            .navigationTitle("Meal plans").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Add meal", systemImage: "plus") { adding = true } }
            .sheet(isPresented: $adding) { QuickAddView(kind: .meal, date: day, fixedKind: true) }
    }
}
