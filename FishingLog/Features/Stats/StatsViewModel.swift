import Foundation
import Combine

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var overview: StatsOverview?
    @Published var seasonal: SeasonalData?
    @Published var species: [SpeciesItem] = []
    @Published var topCatches: [TopCatch] = []
    @Published var isLoading = false
    @Published var error: String?

    var selectedYear: Int = Calendar.current.component(.year, from: Date()) {
        didSet { Task { await fetchSeasonal() } }
    }

    func fetchAll() async {
        isLoading = true
        error = nil
        do {
            async let ov = APIClient.shared.fetchStatsOverview()
            async let seas = APIClient.shared.fetchSeasonal(year: selectedYear)
            async let sp = APIClient.shared.fetchSpecies()
            async let tc = APIClient.shared.fetchTopCatches()
            (overview, seasonal, species, topCatches) = try await (ov, seas, sp, tc)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func fetchSeasonal() async {
        do {
            seasonal = try await APIClient.shared.fetchSeasonal(year: selectedYear)
        } catch {}
    }
}
