import 'package:flutter/material.dart';
import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

void main() {
  runApp(const RecorderOverlay(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recorder Demo',
      navigatorObservers: [RecorderOverlay.navigatorObserver],
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => const LoginPage(),
        '/home': (ctx) => const HomePage(),
        '/profile': (ctx) => const ProfilePage(),
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TestIdTextField(
                id: 'username_field',
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TestIdTextField(
                id: 'password_field',
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              TestId(
                id: 'login_button',
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  child: const Text('Login'),
                ),
              ),
              const SizedBox(height: 12),
              TestId(
                id: 'register_link',
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Create an account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          TestId(
            id: 'profile_button',
            child: IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (ctx, i) => TestId(
          id: 'item_${i + 1}',
          child: ListTile(
            title: Text('Item ${i + 1}'),
            subtitle: Text('Description for item ${i + 1}'),
            onTap: () {},
          ),
        ),
      ),
      floatingActionButton: TestId(
        id: 'add_button',
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
            const SizedBox(height: 16),
            const Text('John Doe', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            TestId(
              id: 'logout_button',
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
