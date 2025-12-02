# hikingTW

這是一款基於 Swift + SwiftUI 開發，用於登山行程規劃與記錄的 iPhone App 原型。

## 功能 (MVP)

- **個人化設定**：使用者可設定「個人配速係數」，依據自身體能調整預估時間。
- **行程規劃**：在地圖上選取節點串成行程。
- **時間估算**：自動計算預估總行程時間（標準時間 × 個人配速係數）。
- **打卡機制**：模擬節點簽到，並可依據實際行走時間更新個人係數。
- **定位與導航**：
    - 內建指南針 (Compass)
    - GPS 定位追蹤 (Location Tracking)

## 專案結構

本專案主要程式碼位於 `hikingAPP/hikingAPP` 目錄下：

- `Models/`：資料模型
    - `Node.swift`：節點資料
    - `Segment.swift`：路段資料
    - `User.swift`：使用者設定
    - `NavigationViewModel.swift`：導航邏輯視圖模型
- `Views/`：SwiftUI 視圖，包括規劃、地圖、摘要頁等
- `Data/`：JSON 格式的內建節點與路段資料
- `Utils/`：工具函式庫
- `hikingAPPApp.swift`：App 入口點，包含 `LocationManager` 與 `CompassManager` 的初始化

## 使用方式

1. 在 Xcode 開啟 `hikingAPP/hikingAPP.xcodeproj` 專案。
2. 確認 `Data/` 資料夾內包含所需的節點與路線 JSON 檔案。
3. 執行 App (Cmd + R)。
4. 在 App 中設定個人配速係數，開始規劃行程或模擬導航。

---

## 後續擴充方向

- 集成 MapKit（SwiftUI `Map`）以更精確視覺化節點與路徑
- 離線儲存行程紀錄（UserDefaults 或 CoreData）
- 支援 GPX 匯出與匯入
- 上傳自訂節點至社群或 GitHub
- 結合 MVVM 架構優化大型邏輯
