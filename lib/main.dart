import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thirst Watch',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0077B6), 
      ),
      home: const WaterIntakeScreen(),
    );
  }
}

class WaterIntakeScreen extends StatefulWidget {
  const WaterIntakeScreen({super.key});

  @override
  _WaterIntakeScreenState createState() => _WaterIntakeScreenState();
}

class _WaterIntakeScreenState extends State<WaterIntakeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _goalController = TextEditingController();
  double waterLeft = 0.0;
  double cumulativeWaterDrank = 0.0; // Track total water consumed
  double dailyGoal = 3000.0; // Default daily goal

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
  // Listen to changes in the "water-intake" node in Firebase
    _database.child('water-intake').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          waterLeft = (data['water_left'] ?? 0.0).toDouble(); // Update water left
          cumulativeWaterDrank = (data['water_drank'] ?? 0.0).toDouble(); // Update cumulative water drank
          if (cumulativeWaterDrank >= dailyGoal) {
            _showGoalAchievedDialog();
          }
        });
      }
    });
  }

  void _showGoalAchievedDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You have achieved your daily water intake goal!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _updateDailyGoal(double newGoal) {
    setState(() {
      dailyGoal = newGoal;
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Water Intake',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white, 
        ),
      ),
      backgroundColor: const Color(0xFF0077B6), 
      elevation: 0,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Always display "Water Left in Bottle"
          _buildProgressBar(
            label: 'Water Left in Bottle',
            value: waterLeft / 500, // Assuming the bottle capacity is 500 ml
            color: const Color(0xFF6A0572), 
            amount: waterLeft,
          ),
          const SizedBox(height: 20),
          // Display "You Drank" progress bar
          _buildProgressBar(
            label: 'You Drank',
            value: cumulativeWaterDrank / dailyGoal, // Adjust based on daily goal
            color: const Color(0xFF6A0572), 
            amount: cumulativeWaterDrank,
          ),
          const SizedBox(height: 40),
          // Display daily goal setter
          _buildDailyGoalSetter(),
        ],
      ),
    ),
  );
}

  Widget _buildProgressBar({
    required String label,
    required double value,
    required Color color,
    required double amount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${amount.toStringAsFixed(1)} ml',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white, 
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0), 
            minHeight: 20,
            backgroundColor: const Color(0xFFE0F7FA), 
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

Widget _buildDailyGoalSetter() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Set Your Daily Goal',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white, 
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TextField for user input
          Expanded(
            child: TextField(
              controller: _goalController, 
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white), 
              decoration: InputDecoration(
                hintText: 'Enter goal in ml',
                hintStyle: const TextStyle(color: Colors.white70), 
                filled: true,
                fillColor: const Color(0xFF6A0572), 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Button to set the goal
          ElevatedButton(
            onPressed: () {
              final double? newGoal = double.tryParse(_goalController.text);
              if (newGoal != null && newGoal > 0) {
                _updateDailyGoal(newGoal); // Update the daily goal
                _goalController.clear(); // Clear the input field
              } else {
                // Show an error if the input is invalid
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A0572), 
            ),
            child: const Text(
              'Set Goal',
              style: TextStyle(color: Colors.white), 
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      // Display the current goal
      Text(
        'Your Goal: ${dailyGoal.toStringAsFixed(1)} ml',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white, 
        ),
      ),
    ],
  );
} 
}