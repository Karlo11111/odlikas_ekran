import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_page_viewmodel.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Fetch data when the homepage is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<HomePageViewModel>();
      viewModel.fetchStudentProfile("karlo.ciciliani@skole.hr", "2kw3xpAS");
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomePageViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Homepage"),
      ),
      body: viewModel.isLoading
          ? Center(child: CircularProgressIndicator())
          : viewModel.studentProfile != null
              ? Column(
                  children: [
                    Text(
                      "Welcome, ${viewModel.studentProfile!['subjects'] ?? 'Student'}",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    // Example: Show other profile data
                    Text(
                        "Email: ${viewModel.studentProfile!['karlo.ciciliani@skole.hr'] ?? ''}"),
                  ],
                )
              : Center(
                  child: Text("No data available"),
                ),
    );
  }
}
