// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    const apiKey = AppConfig.apiKey;
    final url = Uri.parse("${AppConfig.apiUrl}/user_authenticate");

    try {
      final response = await http.post(
        url,
        body: {
          "api_key_token": apiKey,
          "username": _usernameController.text,
          "password": _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["code"] == "100" && data["payload"] is Map) {
          final payload = data['payload'] as Map<String, dynamic>;

          // CORRECTED: Properly parse the cookie string.
          final String? rawCookie = response.headers['set-cookie'];
          if (rawCookie != null) {
            // The 'Set-Cookie' header can be "name=value; expires=...; path=...".
            // We only need the "name=value" part for the 'Cookie' header.
            int separatorIndex = rawCookie.indexOf(';');
            String validCookie = (separatorIndex == -1) ? rawCookie : rawCookie.substring(0, separatorIndex);
            payload['cookie'] = validCookie;
          }

          Navigator.of(context).pushReplacementNamed(
            '/feed',
            arguments: payload,
          );
        } else {
          setState(() {
            _errorMessage = data["message"] ?? "Login failed: Invalid credentials.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Network error: Failed to connect to the server.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username or Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter your username" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter your password" : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _login();
                        }
                      },
                      child: const Text("Login"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}