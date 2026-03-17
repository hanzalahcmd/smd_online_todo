//22k-4156,22k-4574, 22k-4431,22k-4494
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Todo {
  final String? id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime? createdAt;

  Todo({
    this.id,
    required this.title,
    required this.description,
    this.isDone = false,
    this.createdAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isDone: json['completed'] == true || json['completed'] == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'completed': isDone,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PaginatedResponse {
  final List<Todo> todos;
  final int total;
  final int page;
  final int limit;

  PaginatedResponse({
    required this.todos,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? json['todos'] ?? json['items'] ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return PaginatedResponse(
      todos: data.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList(),
      total: pagination['total'] as int? ?? json['total'] as int? ?? data.length,
      page: pagination['page'] as int? ?? json['page'] as int? ?? 1,
      limit: pagination['limit'] as int? ?? json['limit'] as int? ?? 10,
    );
  }
}

class AddTodoRequest {
  final String title;
  final String description;

  AddTodoRequest({required this.title, required this.description});

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'completed': false,
      };
}

class UpdateTodoRequest {
  final String title;
  final String description;
  final bool isDone;

  UpdateTodoRequest({
    required this.title,
    required this.description,
    required this.isDone,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'completed': isDone,
      };
}

class TodoApiService {
  static const String _baseUrl = 'https://apimocker.com/todos';
  static const int _pageSize = 10;

  Future<PaginatedResponse> fetchTodos({int page = 1}) async {
    final uri = Uri.parse('$_baseUrl?page=$page&limit=$_pageSize&_sort=id&_order=desc');
    final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is List) {
        final todos = decoded
            .map((e) => Todo.fromJson(e as Map<String, dynamic>))
            .toList();
        return PaginatedResponse(
          todos: todos,
          total: todos.length,
          page: page,
          limit: _pageSize,
        );
      }
      return PaginatedResponse.fromJson(decoded as Map<String, dynamic>);
    }
    throw ApiException('Failed to load todos (${response.statusCode}): ${response.body}');
  }

  Future<Todo> addTodo(AddTodoRequest request) async {
    final uri = Uri.parse(_baseUrl);
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final resource = decoded['data'] ?? decoded;
        return Todo.fromJson(resource as Map<String, dynamic>);
      }
      throw ApiException('Unexpected response format');
    }
    throw ApiException('Failed to add todo (${response.statusCode}): ${response.body}');
  }

  Future<Todo> updateTodo(String id, UpdateTodoRequest request) async {
    final uri = Uri.parse('$_baseUrl/$id');
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final resource = decoded['data'] ?? decoded;
        return Todo.fromJson(resource as Map<String, dynamic>);
      }
      throw ApiException('Unexpected response format');
    }
    throw ApiException('Failed to update todo (${response.statusCode}): ${response.body}');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TodoApiService _api = TodoApiService();
  final ScrollController _scrollController = ScrollController();

  final List<Todo> _todos = [];
  int _currentPage = 1;
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTodos(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadTodos();
    }
  }

  Future<void> _loadTodos({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoadingInitial = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMore = true;
        _todos.clear();
      });
    } else {
      if (_isLoadingMore || !_hasMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final result = await _api.fetchTodos(page: _currentPage);
      setState(() {
        _todos.addAll(result.todos);
        _currentPage++;
        _hasMore = result.todos.length >= 10;
        _isLoadingInitial = false;
        _isLoadingMore = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingInitial = false;
        _isLoadingMore = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _toggleDone(Todo todo) async {
    if (todo.id == null) return;

    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index == -1) return;

    final updated = todo.copyWith(isDone: !todo.isDone);
    setState(() => _todos[index] = updated);

    try {
      final result = await _api.updateTodo(
        todo.id!,
        UpdateTodoRequest(
          title: todo.title,
          description: todo.description,
          isDone: updated.isDone,
        ),
      );
      setState(() => _todos[index] = result);
    } catch (e) {
      setState(() => _todos[index] = todo);
      if (mounted) {
        _showSnackBar('Failed to update: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddTodoSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => AddTodoSheet(
        onAdd: (todo) {
          setState(() => _todos.insert(0, todo));
          _showSnackBar('Todo added!');
        },
        api: _api,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('My Todos'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _loadTodos(reset: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTodoSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Todo'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _todos.isEmpty) {
      return _ErrorView(
        message: _errorMessage!,
        onRetry: () => _loadTodos(reset: true),
      );
    }

    if (_todos.isEmpty) {
      return _EmptyView(onAdd: _openAddTodoSheet);
    }

    return RefreshIndicator(
      onRefresh: () => _loadTodos(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _todos.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _todos.length) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return TodoCard(
            todo: _todos[index],
            onToggle: () => _toggleDone(_todos[index]),
          );
        },
      ),
    );
  }
}

class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;

  const TodoCard({super.key, required this.todo, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDone = todo.isDone;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isDone ? 0 : 1,
      color: isDone ? cs.surfaceContainerHighest : cs.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? cs.primary : Colors.transparent,
                    border: Border.all(
                      color: isDone ? cs.primary : cs.outline,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? Icon(Icons.check, size: 14, color: cs.onPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: tt.titleMedium?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? cs.onSurface.withOpacity(0.5) : cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      todo.description,
                      style: tt.bodyMedium?.copyWith(
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? cs.onSurfaceVariant.withOpacity(0.5)
                            : cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (todo.createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(todo.createdAt!),
                        style: tt.bodySmall?.copyWith(color: cs.outline),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  isDone ? 'Done' : 'Pending',
                  style: tt.labelSmall?.copyWith(
                    color: isDone ? cs.onPrimaryContainer : cs.onSecondaryContainer,
                  ),
                ),
                backgroundColor:
                    isDone ? cs.primaryContainer : cs.secondaryContainer,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class AddTodoSheet extends StatefulWidget {
  final Function(Todo) onAdd;
  final TodoApiService api;

  const AddTodoSheet({super.key, required this.onAdd, required this.api});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      final request = AddTodoRequest(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
      );
      final todo = await widget.api.addTodo(request);
      widget.onAdd(todo);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('New Todo',
                    style: tt.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'What needs to be done?',
                prefixIcon: Icon(Icons.title),
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Title is required';
                }
                if (v.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                if (v.trim().length > 100) {
                  return 'Title must be under 100 characters';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the task...',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Description is required';
                }
                if (v.trim().length < 5) {
                  return 'Description must be at least 5 characters';
                }
                if (v.trim().length > 500) {
                  return 'Description must be under 500 characters';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.add_task),
              label: Text(_isSubmitting ? 'Adding...' : 'Add Todo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: cs.error),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_rounded, size: 72, color: cs.primary),
            const SizedBox(height: 16),
            Text('No todos yet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tap the button below to add your first todo',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Todo'),
            ),
          ],
        ),
      ),
    );
  }
}