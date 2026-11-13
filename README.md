# CheKita — Small Business Costing and Profit Analyzer (iOS · SwiftUI · Firebase)

- **Bundle ID:** `com.chekita.CheKita`
- **Firebase project:** `chekita-a49c8`, configured by `CheKita/GoogleService-Info.plist`
- **Firebase services used:** Authentication + Cloud Firestore only. **No Firebase Storage**, so photos cost nothing.

## 1. Firebase Console setup (one time)
Open https://console.firebase.google.com and select the **chekita-a49c8** project.

1. **Authentication → Sign-in method:** enable **Email/Password**.
2. **Firestore Database:** click *Create database* and choose a location.
3. **Security rules:** publish `firebase/firestore.rules`, either way:
   - **Console:** paste the file into *Firestore → Rules* and publish.
   - **CLI:**
     ```
     npm i -g firebase-tools
     cd firebase
     firebase login
     firebase deploy --only firestore:rules
     ```

Storage does **not** need to be enabled.

## 2. Open & run
1. Open `CheKita.xcodeproj` in **Xcode 16.3 or newer**.
2. Xcode fetches the Firebase SDK automatically (Swift Package `firebase-ios-sdk` 12.x; products: FirebaseCore, FirebaseAuth, FirebaseFirestore). If it doesn't, use *File → Packages → Resolve Package Versions*.
3. Pick your Team under *Signing & Capabilities*, choose an iPhone (iOS 17+) and press **Run**.
4. Sign up with any email and password. A new account starts with sample bakery data; clear it from *Profile → App Settings → Clear All Data*.

## Features
- **Auth:** sign up, login, logout, forgot password (reset email), change password. The session persists between launches.
- **Products:** 4-step create/edit flow (details → ingredients → profit calculator → review) with swipe-to-delete and confirmation.
- **Inventory:** materials with cost per unit, stock, categories and photos.
- **Labor & other costs:** each product can carry extra costs — labor, gas/electricity, packaging, delivery — set **per batch** or **per piece**. They are added to the ingredient cost, so cost per piece and SRP reflect real expenses.
- **Record Production:** saves the batch, raises product stock and (optionally) deducts ingredients — in one Firestore write.
- **Record Sale:** quantity, selling price (suggested SRP pre-filled), date, channel and customer. It lowers the stock and stores the real revenue, cost and profit. Deleting a sale returns the pieces to stock.
- **Reports:** a **Production / Sales** switch. Production opens the recipe report with a PDF export; Sales shows real income with totals for sales, cost and profit.
- **Home:** product, cost and estimated-profit cards, plus this month's actual sales, profit and best seller.

## Costing formulas (`Utilities/CostCalculator.swift`)
```
ingredient cost = quantity × cost per unit        (units are converted, g ↔ kg…)
overhead cost   = Σ per-batch amounts + Σ per-piece amounts × yield
total cost      = ingredient cost + overhead cost
cost per piece  = total cost ÷ yield
profit %        = (selling price × yield − total cost) ÷ total cost × 100
suggested SRP   = cost per piece × (1 + profit %)
estimated profit= (SRP − cost per piece) × yield
actual profit   = (selling price − cost per piece) × quantity sold
```
In Step 3 you type the **Selling Price Target** and the profit percentage is computed from it.
Ingredient prices are always read from current inventory, so changing a material's price updates every product that uses it.

## Data in Firestore
| Data | Location |
|---|---|
| Profile | `users/{uid}` — fullName, email, businessName, avatarData, workspaceSeeded |
| Products | `users/{uid}/products/{id}` — with `ingredients` and `overheads` arrays |
| Inventory | `users/{uid}/materials/{id}` |
| Production | `users/{uid}/productionRecords/{id}` — scaled ingredient and overhead lines |
| Sales | `users/{uid}/sales/{id}` — quantity, unitPrice, unitCost, channel, customer |
| Reports | `users/{uid}/reports/summary` — production and sales totals, recomputed on every change |

The rules only let a signed-in user read and write their own `users/{uid}` subtree.

## Photos (no Firebase Storage)
Every photo is kept twice:
- the **full-size JPEG on the device** (Application Support), used whenever it is there;
- a **small thumbnail (~50 KB) as base64 inside the Firestore document** (`imageData` / `avatarData`), so the photo still shows after a reinstall or on another phone.

Thumbnails are capped well under Firestore's 1 MB document limit, and the rules reject anything larger than 400 KB. `Services/ImageStore.swift` holds all of this.

To bundle real photos for the sample data instead, add image sets named like `food_chocolate_chip_cookie` or `material_all_purpose_flour` to `Assets.xcassets`.

## Project structure (MVVM)
```
CheKita/
  CheKitaApp.swift          App entry; configures Firebase, injects Session / DataStore / Router
  Models/                   Product, Material, OverheadCost, ProductionRecord, SaleRecord, User, Report
  ViewModels/               Session, Auth, CreateProduct (4 steps), MaterialForm, DataStore, AppRouter
  Services/                 Firebase auth + Firestore repository, ImageStore, PDF report, seed data
  Utilities/                Theme tokens, formatters, CostCalculator, validators
  Views/                    Splash, Onboarding, Auth, Main (tab bar), Home, Products,
                            CreateProduct, Inventory, Reports, Profile, Components
  Assets.xcassets           chekitaapp_logo, splashscreen, chekita_onboard, AppIcon, AccentColor
firebase/                   firestore.rules, indexes, firebase.json
```
