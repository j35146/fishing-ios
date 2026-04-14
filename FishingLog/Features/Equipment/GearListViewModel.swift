import Foundation
import Combine

@MainActor
final class GearListViewModel: ObservableObject {
    @Published var equipments: [Equipment] = []
    @Published var categories: [EquipmentCategory] = []
    @Published var selectedGroup: EquipmentGroup = .traditional
    @Published var selectedCategoryId: Int? = nil
    @Published var isLoading = false
    @Published var error: String?

    // 当前大类下的小类列表
    var filteredCategories: [EquipmentCategory] {
        categories.filter { $0.groupCode == selectedGroup.rawValue }
    }

    func refresh() async {
        isLoading = true
        error = nil
        do {
            async let cats = APIClient.shared.fetchCategories()
            async let equip = APIClient.shared.fetchEquipment(categoryId: selectedCategoryId)
            (categories, equipments) = try await (cats, equip)
            CoreDataManager.shared.upsertEquipments(equipments)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // 切换大类时重置小类筛选
    func selectGroup(_ group: EquipmentGroup) {
        selectedGroup = group
        selectedCategoryId = nil
        Task { await refresh() }
    }

    // 选择小类
    func selectCategory(_ catId: Int?) {
        selectedCategoryId = catId
        Task { await refresh() }
    }

    func deleteEquipment(id: String) async {
        do {
            try await APIClient.shared.deleteEquipment(id: id)
            equipments.removeAll { $0.id == id }
            CoreDataManager.shared.deleteEquipmentById(id: id)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
