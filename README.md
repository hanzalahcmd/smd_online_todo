# ✅ Flutter Todo App

A clean, production-ready **Flutter Todo application** that integrates with a REST API. Features infinite scrolling pagination, optimistic UI updates, dark/light theme support, and full CRUD operations.

---

## 📱 Screenshots

> _Add your screenshots here_

---

## ✨ Features

- **View Todos** — Paginated list with infinite scroll (10 items/page)
- **Add Todos** — Modal bottom sheet with form validation
- **Toggle Completion** — Tap any todo to mark it done/pending with optimistic updates
- **Pull to Refresh** — Swipe down to reload the list
- **Error Handling** — Graceful error state with retry support
- **Empty State** — Friendly UI when no todos exist
- **Dark / Light Theme** — Follows system theme automatically (Material 3)

---

## 🏗️ Project Structure

```
lib/
├── main.dart               # Entry point, app theme setup
│
├── models/
│   ├── Todo                # Todo data model with fromJson/toJson/copyWith
│   ├── PaginatedResponse   # Wrapper for paginated API responses
│   ├── AddTodoRequest      # Request model for creating todos
│   └── UpdateTodoRequest   # Request model for updating todos
│
├── services/
│   └── TodoApiService      # HTTP client — fetch, add, update todos
│
└── screens & widgets/
    ├── TodoListScreen      # Main screen with pagination logic
    ├── TodoCard            # Individual todo card widget
    ├── AddTodoSheet        # Modal bottom sheet form
    ├── _ErrorView          # Error state widget
    └── _EmptyView          # Empty state widget
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.0.0`
- Dart `>=3.0.0`
- An internet connection (app connects to a live REST API)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/flutter-todo-app.git
   cd flutter-todo-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔧 Configuration

The API base URL is set in `TodoApiService`:

```dart
static const String _baseUrl = 'https://apimocker.com/todos';
static const int _pageSize = 10;
```

Replace `_baseUrl` with your own API endpoint if needed.

### Expected API Contract

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/todos?page=1&limit=10` | Fetch paginated todos |
| `POST` | `/todos` | Create a new todo |
| `PATCH` | `/todos/:id` | Update an existing todo |

**Todo object shape:**
```json
{
  "id": "1",
  "title": "Buy groceries",
  "description": "Milk, eggs, bread",
  "completed": false,
  "createdAt": "2024-01-01T12:00:00Z"
}
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.0.0
```

Add to your `pubspec.yaml` and run `flutter pub get`.

---

## 🎨 Theme

The app uses **Material 3** with a purple color seed (`0xFF6750A4`) and automatically switches between light and dark mode based on the system setting.

---

## ✅ Form Validation Rules

| Field | Rules |
|-------|-------|
| Title | Required · Min 3 chars · Max 100 chars |
| Description | Required · Min 5 chars · Max 500 chars |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 👨‍💻 Authors

- **22k-4156**
- **22k-4574**
- **22k-4431**
- **22k-4494**

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
