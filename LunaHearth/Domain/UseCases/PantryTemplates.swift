import Foundation

struct PantryTemplateSection: Identifiable, Sendable {
    let category: PantryCategory
    let names: [String]
    var id: PantryCategory { category }
}

extension PantryStyle {
    /// Bundled checklists, not claims about a household or AI-generated results.
    var template: [PantryTemplateSection] {
        switch self {
        case .southIndian: [
            PantryTemplateSection(category: .grains, names: ["Rice", "Idli rice", "Basmati rice", "Brown rice", "Rava", "Poha", "Ragi flour", "Rice flour", "Atta", "Besan", "Maida", "Oats", "Vermicelli", "Pearl millet", "Foxtail millet", "Little millet", "Sorghum flour", "Sago"]),
            PantryTemplateSection(category: .pulses, names: ["Toor dal", "Urad dal", "Moong dal", "Chana dal", "Masoor dal", "Chickpeas", "Black chickpeas", "Green gram", "Black-eyed peas", "Horse gram", "Roasted gram", "Rajma"]),
            PantryTemplateSection(category: .spices, names: ["Mustard seeds", "Cumin seeds", "Fenugreek seeds", "Coriander seeds", "Fennel seeds", "Black pepper", "Turmeric", "Dried red chillies", "Red chilli powder", "Coriander powder", "Cumin powder", "Asafoetida", "Cinnamon", "Cloves", "Green cardamom", "Bay leaves", "Star anise", "Nutmeg", "Sambar powder", "Rasam powder", "Garam masala", "Idli podi", "Sesame seeds", "Poppy seeds", "Ajwain", "Dried ginger"]),
            PantryTemplateSection(category: .produce, names: ["Onions", "Shallots", "Tomatoes", "Potatoes", "Sweet potatoes", "Carrots", "Green beans", "Peas", "Okra", "Eggplant", "Drumstick pods", "Bottle gourd", "Ridge gourd", "Bitter gourd", "Pumpkin", "Cabbage", "Cauliflower", "Spinach", "Curry leaves", "Cilantro", "Mint", "Ginger", "Garlic", "Green chillies", "Coconut", "Lemon", "Banana", "Mango", "Cucumber", "Beetroot"]),
            PantryTemplateSection(category: .chilled, names: ["Milk", "Yogurt", "Buttermilk", "Butter", "Paneer", "Eggs", "Idli batter", "Dosa batter"]),
            PantryTemplateSection(category: .essentials, names: ["Groundnut oil", "Sesame oil", "Coconut oil", "Sunflower oil", "Ghee", "Salt", "Sugar", "Jaggery", "Tamarind", "Tea", "Coffee", "Honey", "Cashews", "Almonds", "Raisins", "Peanuts", "Dried coconut", "Papad", "Pickle", "Coconut milk", "Baking soda", "Baking powder"]),
        ]
        case .indian: [
            PantryTemplateSection(category: .grains, names: ["Atta", "Basmati rice", "Rice", "Brown rice", "Maida", "Besan", "Rava", "Poha", "Oats", "Cornstarch", "Maize flour", "Pearl millet flour", "Sorghum flour", "Buckwheat flour", "Sago", "Vermicelli", "Bread", "Pasta"]),
            PantryTemplateSection(category: .pulses, names: ["Toor dal", "Moong dal", "Masoor dal", "Urad dal", "Chana dal", "Chickpeas", "Black chickpeas", "Rajma", "Green gram", "Black-eyed peas", "Dried green peas", "Moth beans"]),
            PantryTemplateSection(category: .spices, names: ["Cumin seeds", "Coriander seeds", "Mustard seeds", "Fenugreek seeds", "Fennel seeds", "Ajwain", "Nigella seeds", "Turmeric", "Red chilli powder", "Kashmiri chilli powder", "Coriander powder", "Cumin powder", "Garam masala", "Chaat masala", "Amchur", "Asafoetida", "Kasuri methi", "Black pepper", "Cinnamon", "Cloves", "Green cardamom", "Black cardamom", "Bay leaves", "Nutmeg", "Mace", "Saffron", "Pomegranate seed powder", "Sesame seeds", "Poppy seeds"]),
            PantryTemplateSection(category: .produce, names: ["Onions", "Tomatoes", "Potatoes", "Cauliflower", "Cabbage", "Carrots", "Peas", "Green beans", "Okra", "Eggplant", "Spinach", "Fresh fenugreek leaves", "Mustard greens", "Bottle gourd", "Bitter gourd", "Pumpkin", "Radish", "Beetroot", "Cucumber", "Bell peppers", "Ginger", "Garlic", "Green chillies", "Cilantro", "Mint", "Lemon", "Banana", "Apple", "Orange", "Mango"]),
            PantryTemplateSection(category: .chilled, names: ["Milk", "Yogurt", "Buttermilk", "Paneer", "Butter", "Cream", "Eggs", "Cheese"]),
            PantryTemplateSection(category: .essentials, names: ["Mustard oil", "Sunflower oil", "Groundnut oil", "Ghee", "Salt", "Black salt", "Sugar", "Jaggery", "Honey", "Tea", "Coffee", "Tamarind", "Cashews", "Almonds", "Raisins", "Peanuts", "Walnuts", "Dates", "Pickle", "Papad", "Rose water", "Baking soda", "Baking powder", "Yeast"]),
        ]
        case .american: [
            PantryTemplateSection(category: .grains, names: ["Rice", "Brown rice", "Pasta", "Spaghetti", "Macaroni", "Oats", "All-purpose flour", "Whole wheat flour", "Cornmeal", "Cornstarch", "Bread", "Tortillas", "Quinoa", "Couscous", "Barley", "Breakfast cereal", "Breadcrumbs", "Crackers", "Pancake mix"]),
            PantryTemplateSection(category: .pulses, names: ["Black beans", "Pinto beans", "Kidney beans", "Chickpeas", "Lentils", "Split peas", "Cannellini beans", "Navy beans"]),
            PantryTemplateSection(category: .spices, names: ["Black pepper", "Paprika", "Smoked paprika", "Cumin powder", "Chilli powder", "Cayenne pepper", "Cinnamon", "Nutmeg", "Dried oregano", "Dried basil", "Dried thyme", "Dried rosemary", "Bay leaves", "Garlic powder", "Onion powder", "Chilli flakes", "Ground ginger", "Italian seasoning", "Cloves", "Dried parsley"]),
            PantryTemplateSection(category: .produce, names: ["Onions", "Garlic", "Potatoes", "Sweet potatoes", "Carrots", "Celery", "Bell peppers", "Tomatoes", "Cucumber", "Broccoli", "Cauliflower", "Spinach", "Lettuce", "Cabbage", "Green beans", "Peas", "Corn", "Zucchini", "Mushrooms", "Avocado", "Lemon", "Lime", "Apple", "Banana", "Orange", "Strawberries", "Blueberries", "Grapes", "Fresh parsley", "Ginger"]),
            PantryTemplateSection(category: .chilled, names: ["Milk", "Yogurt", "Butter", "Eggs", "Cheddar cheese", "Mozzarella", "Parmesan", "Cream cheese", "Sour cream", "Cream", "Cottage cheese"]),
            PantryTemplateSection(category: .essentials, names: ["Olive oil", "Canola oil", "Vegetable oil", "Salt", "Sugar", "Brown sugar", "Honey", "Maple syrup", "Peanut butter", "Jam", "Tomato sauce", "Tomato paste", "Canned tomatoes", "Ketchup", "Mustard", "Mayonnaise", "Soy sauce", "Hot sauce", "White vinegar", "Apple cider vinegar", "Balsamic vinegar", "Baking soda", "Baking powder", "Yeast", "Vanilla extract", "Cocoa powder", "Chocolate chips", "Almonds", "Walnuts", "Raisins", "Chicken stock", "Vegetable stock", "Canned tuna", "Tea", "Coffee"]),
        ]
        case .everyday: [
            PantryTemplateSection(category: .grains, names: ["Rice", "Pasta", "Oats", "Flour", "Bread", "Tortillas", "Quinoa", "Breakfast cereal", "Breadcrumbs", "Cornstarch"]),
            PantryTemplateSection(category: .pulses, names: ["Lentils", "Chickpeas", "Kidney beans", "Black beans", "Split peas"]),
            PantryTemplateSection(category: .spices, names: ["Black pepper", "Cumin seeds", "Turmeric", "Paprika", "Cinnamon", "Dried oregano", "Chilli powder", "Bay leaves"]),
            PantryTemplateSection(category: .produce, names: ["Onions", "Potatoes", "Tomatoes", "Carrots", "Garlic", "Ginger", "Spinach", "Broccoli", "Peas", "Green beans", "Cucumber", "Bell peppers", "Lemon", "Banana", "Apple", "Orange"]),
            PantryTemplateSection(category: .chilled, names: ["Milk", "Eggs", "Yogurt", "Butter", "Cheese"]),
            PantryTemplateSection(category: .essentials, names: ["Cooking oil", "Salt", "Sugar", "Tea", "Coffee", "Honey", "Peanut butter", "Jam", "Tomato paste", "Canned tomatoes", "Vinegar", "Baking powder", "Baking soda", "Almonds", "Raisins", "Vegetable stock"]),
        ]
        }
    }
}
