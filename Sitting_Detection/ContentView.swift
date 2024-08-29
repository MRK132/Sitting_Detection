import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StandingViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Standing Status")
                .font(.largeTitle)
            
            Text("Current hour standing complete: \(viewModel.isCurrentHourComplete ? "Yes" : "No")")
                .font(.headline)
            
            Text("Continuous sitting hours: \(viewModel.continuousSittingHours)")
                .font(.headline)
        }
        .padding()
        .onAppear {
            viewModel.startPeriodicChecks()
        }
        .onDisappear {
            viewModel.stopPeriodicChecks()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.fetchStandingData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
