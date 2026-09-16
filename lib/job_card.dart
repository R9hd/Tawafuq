
import 'package:flutter/material.dart';

const int jobDescriptionLimit = 100;

String getShortjobDescription(String jobDescription) {
  if (jobDescription.length > jobDescriptionLimit) {
    return '${jobDescription.substring(0, jobDescriptionLimit)}...';
  }
  return jobDescription;
}

class JobCard extends StatelessWidget {
  final String jobTitle;
  final String jobDescription;
  final String jobLocation;
  final String jobType;
  final String jobId;
  final String jobSalary;

  const JobCard({
    super.key,
    required this.jobTitle,
    required this.jobDescription,
    required this.jobLocation,
    required this.jobType,
    required this.jobId,
    required this.jobSalary,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 150,
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jobTitle,
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF244855),
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Expanded(
                child: Text(
                  getShortjobDescription(jobDescription),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Job Type: $jobType',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: const Color(0xFFD76315),
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Job Location: $jobLocation',
                style: TextStyle(
                    fontSize: screenWidth * 0.045, 
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Job Salary: $jobSalary',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
