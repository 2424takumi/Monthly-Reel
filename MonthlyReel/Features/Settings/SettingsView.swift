import SwiftUI
import Photos

/// App settings screen with photo library status, quality picker, data management, and version info.
struct SettingsView: View {
    @State private var selectedQuality: ExportQuality = {
        let raw = UserDefaults.standard.string(forKey: "reelQuality") ?? "standard"
        return ExportQuality(rawValue: raw) ?? .standard
    }()
    @State private var showDeleteAlert = false
    @State private var photoAuthStatus: PHAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                settingsList
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear { refreshAuthStatus() }
    }
}

// MARK: - Settings List

private extension SettingsView {
    var settingsList: some View {
        List {
            photoLibrarySection
            qualitySection
            dataSection
            aboutSection
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }
}

// MARK: - Photo Library Section

private extension SettingsView {
    var photoLibrarySection: some View {
        Section {
            HStack {
                Label("写真ライブラリ", systemImage: "photo.on.rectangle")
                    .font(.system(size: 15, design: .rounded))

                Spacer()

                Text(authStatusText)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(authStatusColor)
            }

            if photoAuthStatus == .denied || photoAuthStatus == .restricted {
                Button {
                    openAppSettings()
                } label: {
                    Label("設定を開く", systemImage: "gear")
                        .font(.system(size: 15, design: .rounded))
                }
            }
        } header: {
            Text("アクセス権限")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    var authStatusText: String {
        switch photoAuthStatus {
        case .authorized: return "許可済み"
        case .limited: return "制限付き"
        case .denied: return "拒否"
        case .restricted: return "制限"
        case .notDetermined: return "未設定"
        @unknown default: return "不明"
        }
    }

    var authStatusColor: Color {
        switch photoAuthStatus {
        case .authorized: return .green
        case .limited: return .yellow
        case .denied, .restricted: return .red
        default: return .white.opacity(0.5)
        }
    }

    func refreshAuthStatus() {
        photoAuthStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Quality Section

private extension SettingsView {
    var qualitySection: some View {
        Section {
            Picker(selection: $selectedQuality) {
                ForEach(ExportQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName)
                        .tag(quality)
                }
            } label: {
                Label("書き出し品質", systemImage: "film")
                    .font(.system(size: 15, design: .rounded))
            }
            .onChange(of: selectedQuality) { _, newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: "reelQuality")
            }
        } header: {
            Text("品質")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .listRowBackground(Color.white.opacity(0.06))
    }
}

// MARK: - Data Section

private extension SettingsView {
    var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("すべてのデータを削除", systemImage: "trash")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.red)
            }
            .alert("すべてのデータを削除しますか？", isPresented: $showDeleteAlert) {
                Button("削除", role: .destructive) {
                    deleteAllData()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("生成したリールがすべて削除されます。この操作は取り消せません。")
            }
        } header: {
            Text("データ管理")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    func deleteAllData() {
        // Clearing the archive directory
        let fileManager = FileManager.default
        guard let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else { return }

        let reelsDirectory = documentsURL.appendingPathComponent("Reels")
        try? fileManager.removeItem(at: reelsDirectory)
        try? fileManager.createDirectory(
            at: reelsDirectory,
            withIntermediateDirectories: true
        )

        UserDefaults.standard.removeObject(forKey: "reelQuality")
    }
}

// MARK: - About Section

private extension SettingsView {
    var aboutSection: some View {
        Section {
            HStack {
                Text("バージョン")
                    .font(.system(size: 15, design: .rounded))
                Spacer()
                Text(appVersion)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }
        } header: {
            Text("アプリ情報")
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .listRowBackground(Color.white.opacity(0.06))
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        return "\(version ?? "1.0") (\(build ?? "1"))"
    }
}
