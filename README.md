# hikingTW

這是一款基於 Swift + SwiftUI 開發，用於「上河時間」登山行程規劃與記錄的 iPhone App 原型。

## 功能 (MVP)

- 使用者設定個人「上河係數」
- 在地圖上選取節點串成行程
- 自動計算預估總行程時間（上河時間 × 使用者係數）
- 打卡機制：模擬節點簽到 → 更新個人係數

## 專案結構

- `Models/`：節點、路段、使用者等資料模型
- `Views/`：SwiftUI 視圖，包括規劃、地圖、摘要頁
- `Data/`：JSON 格式的內建節點與路段資料
- `Utils/`：時間運算工具
- `ShangHeTimeAppApp.swift`：App 入口點

## 使用方式

1. 在 Xcode 建立 SwiftUI App 專案，替換資料夾內容。
2. 在 `Data/` 裡放入你的節點與路線 JSON 檔案。
3. 執行 App，設定上河係數，模擬選取節點，查看預估時間。

---

## 後續擴充方向

- 集成 MapKit（SwiftUI `Map`）以視覺化節點
- 加入 CoreLocation 支援 GPS / 打卡
- 離線儲存行程紀錄（UserDefaults 或 CoreData）
- 支援 GPX 匯出
- 上傳自訂節點至 GitHub、支援 Pull Request
- 結合 MVVM 架構處理大型邏輯
