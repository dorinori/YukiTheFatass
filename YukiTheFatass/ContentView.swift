import SwiftUI

struct ContentView: View {
    @State private var scannedCode = ""
    @State private var productName = ""
    @State private var ingredients = ""
    @State private var isSafeForDogs: Bool? = nil
    
    enum ScanMode {
            case barcode, ingredients
        }
        @State private var scanMode: ScanMode = .barcode
        @State private var showingIngredientsScanner = false
    
    // Color scheme
    let pastelPink = Color(red: 1.0, green: 0.85, blue: 0.85)
    let darkPink = Color(red: 0.8, green: 0.5, blue: 0.5)
    let safeGreen = Color(red: 0.6, green: 0.8, blue: 0.6)
    let dangerRed = Color(red: 0.9, green: 0.5, blue: 0.5)
    let moderateYellow = Color(red: 0.85, green: 0.75, blue: 0.4)
    
    let harmfulIngredients = [
        // Sweeteners
        "xylitol", "erythritol", "artificial sweetener", "sugar alcohol",
        
        // Chocolate/Caffeine
        "chocolate", "cocoa", "theobromine", "caffeine", "coffee", "tea",
        
        // Fruits
        "grape", "raisin", "currant", "sultana",
        
        // Alliums
        "onion", "garlic", "chive", "leek", "shallot", "allium",
        
        // Alcohol
        "alcohol", "ethanol", "beer", "wine", "liquor", "hops",
        
        // Nuts
        "macadamia", "walnut", "black walnut",
        
        // Other
        "avocado", "persin", "yeast dough", "raw yeast", "nutmeg", "rhubarb",
        "green tomato", "green potato", "solanine", "cherry pit", "peach pit",
        "plum pit", "persimmon seed", "mold", "mould", "penicillin", "poppy seed"
    ]
    
    let moderateRiskIngredients = [
        // High-Fat
        "bacon", "fatty meat", "fried food", "lard", "shortening",
        
        // Salt/Sodium
        "salt", "sodium", "soy sauce", "bouillon", "stock cube",
        
        // Dairy
        "milk", "cheese", "cream", "lactose", "ice cream",
        
        // Bones
        "cooked bone", "poultry bone", "fish bone",
        
        // Raw Foods
        "raw egg", "raw fish", "raw salmon", "raw meat",
        
        // Spices
        "cinnamon", "cayenne", "chili", "hot pepper",
        
        // Other
        "sugar", "corn syrup", "bread", "dough", "rawhide"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Your existing background and conditional views...
                pastelPink.edgesIgnoringSafeArea(.all)
                
                if scanMode == .barcode && scannedCode.isEmpty {
                    BarcodeScannerView(scannedCode: $scannedCode)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    productInfoView
                }
            }
            // Add these modifiers to the ZStack:
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Picker("Scan Mode", selection: $scanMode) {
                        Text("Barcode").tag(ScanMode.barcode)
                        Text("Ingredients").tag(ScanMode.ingredients)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                }
            }
            .sheet(isPresented: $showingIngredientsScanner) {
                IngredientsScannerView(foundIngredients: $ingredients)
            }
            .onChange(of: scanMode) { newMode in
                if newMode == .ingredients {
                    showingIngredientsScanner = true
                } else {
                    scannedCode = ""
                }
            }
            // Keep all your existing modifiers:
            .navigationTitle("yuki is fat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "pawprint.fill")
                        Text("yuki is fat")
                            .font(.headline)
                            .foregroundColor(darkPink)
                    }
                }
            }
            .onChange(of: scannedCode) { newCode in
                fetchProductInfo(for: newCode)
            }
            .accentColor(darkPink)
        }
    }
    // MARK: - View Components
    
    private var productInfoView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Product Card
                VStack(alignment: .leading, spacing: 12) {
                    productNameView
                    Divider().background(darkPink)
                    safetyIndicatorView
                    ingredientsView
                }
                .padding()
                .background(.white)
                .cornerRadius(15)
                .shadow(radius: 5)
                .padding(.horizontal)
                
                scanAgainButton
            }
            .padding(.top, 20)
        }
    }
    
    private var productNameView: some View {
        Group {
            if let url = productURL {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text(productName.isEmpty ? "unknown product" : productName.lowercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(darkPink)
                        
                        Image(systemName: "arrow.up.forward.square")
                            .foregroundColor(darkPink)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(productName.isEmpty ? "unknown product" : productName.lowercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(darkPink)
            }
        }
    }
    
    private var safetyIndicatorView: some View {
        Group {
            if let isSafe = isSafeForDogs {
                if productName == "Unknown Product" ||
                           ingredients.isEmpty ||
                           ingredients.lowercased() == "ingredients unavailable" {
                    // Case: Unknown product or no ingredients
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.gray)
                        Text("Cannot determine safety")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                } else {
                    // Normal case with known safety
                    HStack(spacing: 8) {
                        Image(systemName: isSafe ? "pawprint.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(isSafe ? safeGreen : dangerRed)
                        Text(isSafe ? "Safe for Yuki!" : "Not safe for Yuki!")
                            .font(.headline)
                            .foregroundColor(isSafe ? safeGreen : dangerRed)
                    }
                    .padding(8)
                    .background(isSafe ? safeGreen.opacity(0.2) : dangerRed.opacity(0.2))
                    .cornerRadius(8)
                }
            } else {
                // Case: Safety not determined yet
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.gray)
                    Text("Scanning product...")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }
    private var ingredientsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main Ingredients Section
            if !parsedIngredients.regularIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ingredients:")
                        .font(.headline)
                        .foregroundColor(darkPink)
                    
                    ForEach(parsedIngredients.regularIngredients, id: \.self) { ingredient in
                        ingredientRow(ingredient)
                    }
                }
            }
            
            // Contains Section
            if !parsedIngredients.containsItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Contains:")
                        .font(.headline)
                        .foregroundColor(darkPink)
                    
                    ForEach(parsedIngredients.containsItems, id: \.self) { item in
                        ingredientRow(item)
                    }
                }
            }
            
            // May Contain Section
            if !parsedIngredients.mayContainItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("May Contain:")
                        .font(.headline)
                        .foregroundColor(darkPink)
                    
                    ForEach(parsedIngredients.mayContainItems, id: \.self) { item in
                        ingredientRow(item)
                    }
                }
            }
            
            if parsedIngredients.regularIngredients.isEmpty &&
               parsedIngredients.containsItems.isEmpty &&
               parsedIngredients.mayContainItems.isEmpty {
                Text("ingredients unavailable")
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
    }

    private func ingredientRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            if isHarmful(text) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(dangerRed)
            } else if isModerateRisk(text) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(moderateYellow)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(safeGreen)
            }
            
            highlightHarmfulWords(in: text)
                .foregroundColor(.black)
        }
        .padding(.vertical, 2)
    }

    private func highlightHarmfulWords(in text: String) -> Text {
        var result = Text("")
        let remainingText = text
        
        // Process each character manually to catch all matches
        var currentWord = ""
        var currentIndex = remainingText.startIndex
        
        while currentIndex < remainingText.endIndex {
            let character = remainingText[currentIndex]
            
            if character.isLetter || character == "'" {
                // Building a word
                currentWord.append(character)
            } else {
                // Check completed word
                if !currentWord.isEmpty {
                    let highlighted = highlightWord(currentWord)
                    result = result + highlighted
                    currentWord = ""
                }
                // Add non-letter character
                result = result + Text(String(character)).foregroundColor(.black)
            }
            
            currentIndex = remainingText.index(after: currentIndex)
        }
        
        // Check any remaining word at the end
        if !currentWord.isEmpty {
            let highlighted = highlightWord(currentWord)
            result = result + highlighted
        }
        
        return result
    }

    private func highlightWord(_ word: String) -> Text {
        let lowercasedWord = word.lowercased()
        
        // Check against stemmed versions of harmful ingredients
        for harmful in harmfulIngredients {
            let stemmedHarmful = harmful.lowercased()
            if lowercasedWord == stemmedHarmful ||
               lowercasedWord == stemmedHarmful + "s" ||
               lowercasedWord == stemmedHarmful + "es" {
                return Text(word).foregroundColor(dangerRed).bold()
            }
        }
        
        // Check against stemmed versions of moderate ingredients
        for moderate in moderateRiskIngredients {
            let stemmedModerate = moderate.lowercased()
            if lowercasedWord == stemmedModerate ||
               lowercasedWord == stemmedModerate + "s" ||
               lowercasedWord == stemmedModerate + "es" {
                return Text(word).foregroundColor(moderateYellow).bold()
            }
        }
        
        return Text(word).foregroundColor(.black)
    }

    
    private var scanAgainButton: some View {
        Button(action: resetScan) {
            HStack {
                Image(systemName: "barcode.viewfinder")
                Text("Scan Another Product")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(darkPink)
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // MARK: - Data Processing
    
    private var parsedIngredients: (regularIngredients: [String], containsItems: [String], mayContainItems: [String]) {
        parseIngredients(ingredients)
    }
    
    private var productURL: URL? {
        guard !scannedCode.isEmpty else { return nil }
        return URL(string: "https://world.openfoodfacts.org/product/\(scannedCode)")
    }
    
    private func resetScan() {
        scannedCode = ""
        productName = ""
        ingredients = ""
        isSafeForDogs = nil
    }
    
    private func fetchProductInfo(for barcode: String) {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(ProductResponse.self, from: data)
                    DispatchQueue.main.async {
                        if let product = decoded.product {
                            productName = product.product_name ?? "Unknown Product"
                            ingredients = product.ingredients_text ?? "ingredients unavailable"
                            checkDogSafety(ingredients: ingredients.lowercased())
                        } else {
                            productName = "Unknown Product"
                            print("No product data found")
                        }
                    }
                } catch {
                    print("Error decoding: \(error)")
                }
            } else if let error = error {
                print("Network error: \(error)")
            }
        }.resume()
    }
    
    private func checkDogSafety(ingredients: String) {
        guard !ingredients.isEmpty else {
            isSafeForDogs = nil
            return
        }
        
        let containsHarmful = harmfulIngredients.contains { ingredient in
            ingredients.contains(ingredient)
        }
        isSafeForDogs = !containsHarmful
    }
    
    private func isHarmful(_ ingredient: String) -> Bool {
        let lowercasedIngredient = ingredient.lowercased()
        let harmfulFound = harmfulIngredients.first { harmful in
            lowercasedIngredient.contains(harmful.lowercased())
        }
        
        return harmfulFound != nil
    }
    
    private func isModerateRisk(_ ingredient: String) -> Bool {
        moderateRiskIngredients.contains { moderate in
            ingredient.lowercased().contains(moderate.lowercased())
        }
    }
    
    private func getHarmfulComponent(_ ingredient: String) -> String? {
        harmfulIngredients.first { harmful in
            ingredient.lowercased().contains(harmful.lowercased())
        }
    }
    
    private func buildIngredientText(_ ingredient: String) -> Text {
        guard let harmful = getHarmfulComponent(ingredient) else {
            return Text(ingredient.lowercased())
        }
        
        let ranges = ingredient.lowercased().ranges(of: harmful.lowercased())
        var result = Text("")
        var currentIndex = ingredient.startIndex
        
        for range in ranges {
            let safePart = String(ingredient[currentIndex..<range.lowerBound]).lowercased()
            if !safePart.isEmpty {
                result = result + Text(safePart)
            }
            
            let harmfulPart = String(ingredient[range]).lowercased()
            result = result + Text(harmfulPart).foregroundColor(.red).bold()
            
            currentIndex = range.upperBound
        }
        
        let remaining = String(ingredient[currentIndex...]).lowercased()
        if !remaining.isEmpty {
            result = result + Text(remaining)
        }
        
        return result
    }
    
    private func extractStatement(from text: String, keyword: String) -> (items: [String], remaining: String) {
        guard let range = text.range(of: keyword) else { return ([], text) }
        
        let afterKeyword = text[range.upperBound...]
        let statementText: String
        let newRemainingText = String(text[..<range.lowerBound])
        
        // Find where the statement ends
        if keyword == "contains " {
            if let mayContainRange = afterKeyword.range(of: "may contain ") {
                statementText = String(afterKeyword[..<mayContainRange.lowerBound])
            } else {
                statementText = String(afterKeyword)
            }
        } else {
            statementText = String(afterKeyword)
        }
        
        // Split by commas only when not inside parentheses
        var items: [String] = []
        var currentItem = ""
        var parenLevel = 0
        
        for char in statementText {
            if char == "," && parenLevel == 0 {
                let trimmed = currentItem.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    items.append(trimmed)
                }
                currentItem = ""
            } else {
                currentItem.append(char)
                if char == "(" || char == "[" || char == "{" {
                    parenLevel += 1
                } else if char == ")" || char == "]" || char == "}" {
                    parenLevel -= 1
                }
            }
        }
        
        // Add last item
        let lastItem = currentItem.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastItem.isEmpty {
            items.append(lastItem)
        }
        
        return (items, newRemainingText)
    }

    
    private func parseIngredients(_ ingredientsText: String) -> (regularIngredients: [String], containsItems: [String], mayContainItems: [String]) {
        let text = ingredientsText.lowercased()
        var containsItems: [String] = []
        var mayContainItems: [String] = []
        var remainingText = text
        
        // Extract may contain first (since it appears after contains)
        let mayContainResult = extractStatement(from: remainingText, keyword: "may contain ")
        mayContainItems = mayContainResult.items
        remainingText = mayContainResult.remaining
        
        // Then extract contains
        let containsResult = extractStatement(from: remainingText, keyword: "contains ")
        containsItems = containsResult.items
        remainingText = containsResult.remaining.trimmingCharacters(in: .whitespacesAndNewlines)

        // Improved regular ingredient parsing
        var regularIngredients: [String] = []
        var current = ""
        var parenLevel = 0
        var bracketLevel = 0
        var braceLevel = 0
        
        for char in remainingText {
            switch char {
            case ",":
                if parenLevel == 0 && bracketLevel == 0 && braceLevel == 0 {
                    let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        regularIngredients.append(trimmed)
                    }
                    current = ""
                } else {
                    current.append(char)
                }
            case "(": parenLevel += 1; current.append(char)
            case ")": parenLevel -= 1; current.append(char)
            case "[": bracketLevel += 1; current.append(char)
            case "]": bracketLevel -= 1; current.append(char)
            case "{": braceLevel += 1; current.append(char)
            case "}": braceLevel -= 1; current.append(char)
            default: current.append(char)
            }
        }
        
        let lastItem = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !lastItem.isEmpty {
            regularIngredients.append(lastItem)
        }
        
        return (regularIngredients, containsItems, mayContainItems)
    }

}

// MARK: - Extensions

extension String {
    func ranges(of substring: String) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        var currentIndex = startIndex
        
        while let range = range(of: substring, range: currentIndex..<endIndex) {
            ranges.append(range)
            currentIndex = range.upperBound
        }
        
        return ranges
    }
}

// MARK: - Data Models

struct ProductResponse: Decodable {
    let product: Product?
}

struct Product: Decodable {
    let product_name: String?
    let ingredients_text: String?
}

// MARK: - Preview

#Preview {
    ContentView()
}
