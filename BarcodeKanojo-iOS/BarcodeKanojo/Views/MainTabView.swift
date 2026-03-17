import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            KanojosListView()
                .tabItem {
                    Label("Kanojos", systemImage: "heart.fill")
                }

            BarcodeScannerView()
                .tabItem {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }

            EnemyBookView()
                .tabItem {
                    Label("Enemies", systemImage: "book.fill")
                }

            MapKanojosView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
        }
    }
}
