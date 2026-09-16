
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tawafuq/pages/bars&drawers/AdminBar.dart';
import 'package:tawafuq/pages/bars&drawers/AdminDrawer.dart';

class Adminhome extends StatefulWidget {
  const Adminhome({super.key});

  @override
  State<Adminhome> createState() => _AdminhomeState();
}

class _AdminhomeState extends State<Adminhome> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: const Adminbar(pageTitle: "Dashboard"),
      drawer: const Admindrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.008,
                  vertical: screenHeight * 0.008),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.016,
                          vertical: screenHeight * 0.016),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('New users', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          SizedBox(
                              height: screenHeight * 0.20,
                              child: NewUsersLineChart()),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.016,
                          vertical: screenHeight * 0.016),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('Most posted jobs', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          SizedBox(
                              height: screenHeight * 0.20,
                              child: TopFieldsBarChart()),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.020),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.016,
                          vertical: screenHeight * 0.016),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text('Visual impairment individuals',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          SizedBox(
                              height: screenHeight * 0.20,
                              child: RecruitmentPieChart()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class NewUsersLineChart extends StatelessWidget {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  NewUsersLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: usersCollection.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Error loading data');
        }

        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

        List<FlSpot> recruiterSpots = [];
        List<FlSpot> jobSeekerSpots = [];

        var recruiters = snapshot.data!.docs.where((doc) => doc['role'] == 'Recruiter');
        var jobSeekers = snapshot.data!.docs.where((doc) => doc['role'] == 'Job Seeker');

        for (int i = 0; i < months.length; i++) {
          recruiterSpots.add(FlSpot(
            i.toDouble(),
            recruiters.where((doc) => doc['joining month'] == months[i]).length.toDouble(),
          ));
          jobSeekerSpots.add(FlSpot(
            i.toDouble(),
            jobSeekers.where((doc) => doc['joining month'] == months[i]).length.toDouble(),
          ));
        }

        return LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: recruiterSpots,
                isCurved: true,
                color: Colors.blue,
                dotData: const FlDotData(show: false),
              ),
              LineChartBarData(
                spots: jobSeekerSpots,
                isCurved: true,
                color: Colors.lightBlueAccent,
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TopFieldsBarChart extends StatelessWidget {
  final CollectionReference jobsCollection =
      FirebaseFirestore.instance.collection('part_time_jobs');

  TopFieldsBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: jobsCollection.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Error loading data');
        }

        Map<String, int> fieldCounts = {};

        for (var doc in snapshot.data!.docs) {
          String field = doc['jobTitle'];
          fieldCounts[field] = (fieldCounts[field] ?? 0) + 1;
        }

        var topFields = fieldCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return BarChart(
          BarChartData(
            barGroups: List.generate(
              topFields.take(3).length,
              (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: topFields[index].value.toDouble(),
                      color: Colors.teal,
                      width: 16,
                    ),
                  ],
                );
              },
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(topFields[value.toInt()].key);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RecruitmentPieChart extends StatelessWidget {
  final CollectionReference contractsCollection =
      FirebaseFirestore.instance.collection('contracts');

  RecruitmentPieChart({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: contractsCollection.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Error loading data');
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Text('No contract data available.');
        }

        int successfulContracts = snapshot.data!.docs
            .where((doc) => doc['status'] == 'successful').length;
        int failedContracts = snapshot.data!.docs
            .where((doc) => doc['status'] == 'failed').length;

        return PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: successfulContracts.toDouble(),
                color: Colors.teal,
                title: '${(successfulContracts / snapshot.data!.docs.length * 100).toStringAsFixed(1)}%',
                radius: 60,
              ),
              PieChartSectionData(
                value: failedContracts.toDouble(),
                color: Colors.redAccent,
                title: '${(failedContracts / snapshot.data!.docs.length * 100).toStringAsFixed(1)}%',
                radius: 60,
              ),
            ],
          ),
        );
      },
    );
  }
}
