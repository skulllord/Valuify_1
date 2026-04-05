# Valuify - Personal Finance Tracker

A premium, CRED-style personal finance app built with Flutter.

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
</div>

---

## 📱 Screenshots

### Core Features
<div align="center">
  <img src="screenshots/login.png" width="200" alt="Login Screen">
  <img src="screenshots/dashboard.png" width="200" alt="Dashboard">
  <img src="screenshots/transactions.png" width="200" alt="Transactions">
  <img src="screenshots/budgets.png" width="200" alt="Budgets">
</div>

### 💰 UPI Wallet & Payments (NEW!)
<div align="center">
  <img src="screenshots/wallet-main.png" width="200" alt="Wallet Dashboard">
  <img src="screenshots/wallet-send-money.png" width="200" alt="Send Money">
  <img src="screenshots/wallet-request-money.png" width="200" alt="Request Money">
  <img src="screenshots/wallet-history.png" width="200" alt="Transaction History">
</div>

### More Features
<div align="center">
  <img src="screenshots/categories.png" width="200" alt="Categories">
  <img src="screenshots/reports.png" width="200" alt="Reports">
  <img src="screenshots/settings.png" width="200" alt="Settings">
  <img src="screenshots/dark-mode.png" width="200" alt="Dark Mode">
</div>

---

## ✨ Features

- 🔐 Authentication (Email/Password + Google Sign-In)
- 💰 Dashboard with animated balance cards
- 📊 Interactive charts (3-month trend, category pie chart)
- 💳 Transaction management (CRUD with receipt photos)
- 🏷️ Custom categories with icons and colors
- 💵 Monthly budgets with progress tracking
- 📈 Reports (CSV export, PDF generation)
- 💸 **UPI Wallet & Mock Payments** (NEW!)
  - Mock wallet with starting balance
  - Send/receive money via UPI
  - Transaction history
  - Real-time balance updates
- 🤖 **AI Savings Advisor** (NEW!)
  - Analyzes your monthly cash flow
  - Identifies top spending categories
  - Generates personalized, rule-based offline saving tips instantly
- ⚙️ Settings (currency, theme, biometric lock)

## Setup Instructions

### Prerequisites

1. Install Flutter SDK (3.x or higher)
2. Install Android Studio / Xcode
3. Set up Firebase project

### Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "Valuify"
3. Enable the following services:
   - Authentication (Email/Password + Google)
   - Cloud Firestore
   - Firebase Storage

4. **For Android:**
   - Download `google-services.json`
   - Place it in `android/app/`

5. **For iOS:**
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/`

### Installation

```bash
# Clone the repository
git clone https://github.com/skulllord/Valuify.git
cd Valuify

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# APK location: build/app/outputs/flutter-apk/
```

## Project Structure

```
lib/
├── main.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── transactions/
│   │   ├── transactions_screen.dart
│   │   └── add_transaction_screen.dart
│   ├── categories/
│   │   └── categories_screen.dart
│   ├── budgets/
│   │   └── budgets_screen.dart
│   ├── reports/
│   │   └── reports_screen.dart
│   └── settings/
│       └── settings_screen.dart
├── widgets/
│   ├── balance_card.dart
│   ├── transaction_item.dart
│   ├── category_icon.dart
│   └── chart_widgets.dart
├── models/
│   ├── user_model.dart
│   ├── transaction_model.dart
│   ├── category_model.dart
│   └── budget_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   └── pdf_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── transaction_provider.dart
│   ├── category_provider.dart
│   ├── budget_provider.dart
│   └── theme_provider.dart
└── utils/
    ├── constants.dart
    ├── colors.dart
    └── helpers.dart
```

## Firestore Structure

```
users/{userId}
  ├── accounts/{accountId}
  ├── categories/{categoryId}
  ├── transactions/{txnId}
  ├── budgets/{budgetId}
  └── settings
```

## Tech Stack

- **Framework:** Flutter 3.x
- **State Management:** Riverpod
- **Backend:** Firebase (Auth, Firestore, Storage)
- **Charts:** FL Chart
- **Authentication:** Firebase Auth + Google Sign-In

## License

MIT License
