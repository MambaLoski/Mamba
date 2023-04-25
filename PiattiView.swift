//
//  PiattiView.swift
//  WIC
//
//  Created by Mattia Faliva on 25/04/23.
//

import SwiftUI
import PhotosUI


struct Dish: Identifiable, Codable {
    var id = UUID()
    var name: String
    var photo: Data
    var description: String
    var recipe: String
    var category: Category
    var duration: String
    var difficulty: String

    enum Category: String, CaseIterable, Codable {
        case antipasto = "Antipasto"
        case primo = "Primo"
        case secondo = "Secondo"
    }
}

class DishViewModel: ObservableObject {
    @Published var dishes: [Dish] = []

    func addDish(_ dish: Dish) {
        dishes.append(dish)
        saveDishes()
    }

    func saveDishes() {
        if let encodedData = try? JSONEncoder().encode(dishes) {
            UserDefaults.standard.set(encodedData, forKey: "Dishes")
        }
    }

    func loadDishes() {
        if let data = UserDefaults.standard.data(forKey: "Dishes"),
           let decodedDishes = try? JSONDecoder().decode([Dish].self, from: data) {
            dishes = decodedDishes
        }
    }
}

struct MainListView: View {
    @StateObject private var viewModel = DishViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(Dish.Category.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(viewModel.dishes.filter { $0.category == category }) { dish in
                            NavigationLink(destination: DishDetailView(dish: dish)) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Image(uiImage: UIImage(data: dish.photo) ?? UIImage())
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        VStack(alignment: .leading) {
                                            Text(dish.name)
                                                .font(.headline)
                                            Text(dish.description)
                                                .font(.subheadline)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
                        .navigationBarTitle("Lista dei piatti")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NavigationLink(destination: DishFormView(viewModel: viewModel)) {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                    }
                    .onAppear(perform: viewModel.loadDishes)
                }
            }

            extension Dish.Category: Identifiable {
                var id: Self { self }
            }

            struct DishFormView: View {
                @Environment(\.presentationMode) var presentationMode
                @ObservedObject var viewModel: DishViewModel
                @State private var name = ""
                @State private var showingImagePicker = false
                @State private var inputImage: UIImage?
                @State private var photo: UIImage?{
                    didSet{
                        guard let photo = photo else { return }
                        viewModel.uploadImage(photo)
                    }
                }
                @State private var description = ""
                @State private var recipe = ""
                @State private var category: Dish.Category = .antipasto
                @State private var duration = ""
                @State private var difficulty = ""

                var body: some View {
                    NavigationView {
                        Form {
                            Section {
                                TextField("Name", text: $name)
                                Button(action: {
                                    // Add your photo picker implementation here
                                    showingImagePicker = true
                                }) {
                                    if let image = photo {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        Text("Select Photo")
                                    }
                                }
                            }
                            Section {
                                TextField("Description", text: $description)
                                TextField("Recipe", text: $recipe)
                            }
                            Section {
                                Picker("Category", selection: $category) {
                                    ForEach(Dish.Category.allCases) { category in
                                        Text(category.rawValue).tag(category)
                                    }
                                }
                                TextField("Duration", text: $duration)
                                TextField("Difficulty", text: $difficulty)
                            }
                        }
                        .navigationBarTitle("Add Dish")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Cancel") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Save") {
                                    guard let photo = photo, let imageData = photo.jpegData(compressionQuality: 0.7) else { return }
                                    let newDish = Dish(name: name, photo: imageData, description: description, recipe: recipe, category: category, duration: duration, difficulty: difficulty)
                                    viewModel.addDish(newDish)
                                    presentationMode.wrappedValue.dismiss()
                                }
                                .disabled(name.isEmpty || photo == nil)
                            }
                        }
                        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                            PHPickerViewController(configuration: imagePickerConfig())
                        }
                    }
                }

                func loadImage(from results: PHPickerResult) {
                    if let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) {
                        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                            DispatchQueue.main.async {
                                guard let image = image as? UIImage else { return }
                                self?.inputImage = image
                            }
                        }
                    }
                }

                func imagePickerConfig() -> PHPickerConfiguration { // Configure the image picker
                    var config = PHPickerConfiguration()
                    config.filter = .images
                    config.selectionLimit = 1
                    return config
                }
            }

struct DishDetailView: View {
    let dish: Dish

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(uiImage: UIImage(data: dish.photo) ?? UIImage())
                    .resizable()
                    .scaledToFit()
                Text(dish.name)
                    .font(.title)
                    .fontWeight(.bold)
                Text(dish.description)
                Divider()
                Text("Recipe")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(dish.recipe)
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Text("Category")
                        Text(dish.category.rawValue)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Duration")
                        Text(dish.duration)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Difficulty")
                        Text(dish.difficulty)
                    }
                }
            }
            .padding()
        }
        .navigationBarTitle("Dish Details", displayMode: .inline)
    }
}

struct MainListView_Previews: PreviewProvider {
    static var previews: some View {
        MainListView()
    }
}
