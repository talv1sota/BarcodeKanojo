import SwiftUI
import PhotosUI

/// Edit product info for a kanojo's associated barcode.
/// Shows form for product name, company, category, comment, and photo.
struct ProductEditView: View {
    let product: Product
    let barcode: String
    let categories: [Category]
    /// Callback: (name, company, categoryId, comment, imageData?)
    let onSave: (String?, String?, Int, String?, Data?) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var productName: String = ""
    @State private var companyName: String = ""
    @State private var selectedCategoryId: Int = 1
    @State private var comment: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                // Product image
                Section("Product Image") {
                    HStack {
                        if let data = selectedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else if let imgURL = product.productImageURL {
                            AsyncCachedImage(url: imgURL, placeholder: Image(systemName: "photo"))
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                                .frame(width: 80, height: 80)
                        }

                        Spacer()

                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .font(.subheadline)
                        }
                    }
                }

                // Product details
                Section("Product Details") {
                    TextField("Product Name", text: $productName)
                    TextField("Company Name", text: $companyName)
                    if !categories.isEmpty {
                        Picker("Category", selection: $selectedCategoryId) {
                            ForEach(categories) { cat in
                                Text(cat.name).tag(cat.id)
                            }
                        }
                    }
                }

                // Comment
                Section("Comment") {
                    TextField("Description or notes", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Barcode (read-only)
                Section("Barcode") {
                    Text(barcode)
                        .font(.body.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        isSaving = true
                        onSave(
                            productName.isEmpty ? nil : productName,
                            companyName.isEmpty ? nil : companyName,
                            selectedCategoryId,
                            comment.isEmpty ? nil : comment,
                            selectedImageData
                        )
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                productName = product.name ?? ""
                companyName = product.companyName ?? ""
                selectedCategoryId = product.categoryId
                comment = product.comment ?? ""
            }
            .onChange(of: selectedPhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
        }
    }
}
