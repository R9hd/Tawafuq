
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tawafuq/job_card.dart';
import 'package:tawafuq/pages/ApplicantCVScreen.dart';
import 'package:tawafuq/pages/BookmarksPage.dart';
import 'package:tawafuq/pages/JobDetailPage.dart';
import 'package:tawafuq/pages/JobSeekerHome.dart';

class PartTimeJobsPage extends StatefulWidget {
  final bool isVoiceSystemEnabled;

  const PartTimeJobsPage({super.key, required this.isVoiceSystemEnabled});

  @override
  _PartTimeJobsPageState createState() => _PartTimeJobsPageState();
}

class _PartTimeJobsPageState extends State<PartTimeJobsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<JobCard> _jobs = [];
  List<JobCard> _filteredJobs = [];
  int _selectedIndex = 1;
  String? _selectedLocation;
  String? _selectedJobType;
  Set<String> _locations = {};
  Set<String> _jobTypes = {};

  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  final String _speechText = '';
  bool _readingJobs = false;
  late bool _isVoiceSystemEnabled;
  int _currentJobIndex = 0;

  @override
  void initState() {
    super.initState();
    _isVoiceSystemEnabled = widget.isVoiceSystemEnabled;
    _fetchJobsFromDatabase().then((_) {
      if (_isVoiceSystemEnabled) {
        _askInitialQuestion();
      }
    });
    if (_isVoiceSystemEnabled) {
      _initializeTTS();
    }
  }

  Future<void> _fetchJobsFromDatabase() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('part_time_jobs').get();
      List<JobCard> fetchedJobs = querySnapshot.docs.map((doc) {
        return JobCard(
          jobTitle: doc['jobTitle'],
          jobDescription: doc['jobDescription'],
          jobLocation: doc['jobLocation'],
          jobType: doc['jobType'],
          jobSalary: doc['jobSalary'],
          jobId: doc.id,
        );
      }).toList();

      setState(() {
        _jobs = fetchedJobs;
        _filteredJobs = fetchedJobs;
        _locations = fetchedJobs.map((j) => j.jobLocation).toSet();
        _jobTypes  = fetchedJobs.map((j) => j.jobType).toSet();
      });
    } catch (e) {
      print('Error fetching jobs: $e');
    }
  }

  void _initializeTTS() {
    _flutterTts.setCompletionHandler(() {
      if (_readingJobs && _currentJobIndex < _filteredJobs.length) {
        _readJobOffer(_currentJobIndex);
      }
    });
  }

  Future<void> _askInitialQuestion() async {
    await _flutterTts.speak(
        "If you want to hear job offers say start. To go to your CV page say CV. To go to the bookmarks page say bookmark. Or say back to return to the home page.");
    await Future.delayed(const Duration(seconds: 10));
    _listenForInitialCommand();
  }

  void _listenForInitialCommand() async {
    bool available = await _speechToText.initialize(onError: (error) {
      print("STT Initialization Error: ${error.errorMsg}");
    });

    if (!available) {
      await _flutterTts.speak("Speech recognition is not available.");
      return;
    }

    bool hasPermission = await _speechToText.hasPermission;
    if (!hasPermission) {
      await _flutterTts.speak("Microphone permissions are required.");
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);

      try {
        await _speechToText.listen(
          onResult: (result) async {
            String userResponse = result.recognizedWords.toLowerCase().trim();
            print("User Response: $userResponse");

            if (userResponse.isNotEmpty) {
              bool commandHandled = _handleInitialCommand(userResponse);
              if (!commandHandled) {
                await _flutterTts.speak("I didn't understand. Please try again.");
                await Future.delayed(const Duration(seconds: 4));
                _listenForInitialCommand();
              }
            } else {
              await _flutterTts.speak("I didn't hear anything. Please say it again.");
              await Future.delayed(const Duration(seconds: 4));
              _listenForInitialCommand();
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 12),
          listenOptions: stt.SpeechListenOptions(partialResults: false),
        );
      } catch (e) {
        print("Error starting STT: $e");
        await _flutterTts.speak("An unexpected error occurred. Please try again.");
      } finally {
        setState(() => _isListening = false);
      }
    }

    _speechToText.errorListener = (error) async {
      print("STT Error: ${error.errorMsg}");
      if (error.errorMsg.contains("error_no_match")) {
        await _flutterTts.speak("I couldn't understand. Please say it again.");
        await Future.delayed(const Duration(seconds: 4));
        _listenForInitialCommand();
      } else {
        await _flutterTts.speak("There was an error. Please try again.");
      }
    };
  }

  void _stopListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  bool _handleInitialCommand(String command) {
    command = command.toLowerCase();

    if (command.contains('start')) {
      _startReadingJobs();
      return true;
    } else if (command.contains('cv')) {
      _stopListening();
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => ApplicantCVScreen(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
      return true;
    } else if (command.contains('bookmark')) {
      _stopListening();
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => BookmarksPage(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
      return true;
    } else if (command.contains('back')) {
      _stopListening();
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => JobSeekerHome(
              applicantName: '', isVoiceSystemEnabled: _isVoiceSystemEnabled)));
      return true;
    }

    return false;
  }

  bool _handleJobReadingCommand(String command) {
    if (command.contains('view') || command.contains('details') || command.contains('see')) {
      _stopListening();
      _navigateToJobDetails();
      return true;
    } else if (command.contains('skip') || command.contains('next')) {
      _currentJobIndex++;
      _readJobOffer(_currentJobIndex);
      return true;
    } else if (command.contains('back') || command.contains('stop')) {
      _readingJobs = false;
      if (_isVoiceSystemEnabled) {
        _askInitialQuestion();
        return true;
      }
    }
    return false;
  }

  void _startReadingJobs() {
    setState(() {
      _readingJobs = true;
      _currentJobIndex = 0;
    });
    _readJobOffer(_currentJobIndex);
  }

  Future<void> _readJobOffer(int index) async {
    await Future.delayed(const Duration(seconds: 5));
    if (index < _filteredJobs.length) {
      String jobTitle = _filteredJobs[index].jobTitle ?? 'No Title';
      String jobLocation = _filteredJobs[index].jobLocation ?? 'No location';

      await _flutterTts.speak(
          "Job Offer ${index + 1}: $jobTitle. Location: $jobLocation. Say view to see job details, skip to hear the next job, or back to stop.");
      await Future.delayed(const Duration(seconds: 10));
      _listenForJobCommand();
    } else {
      await _flutterTts.speak("You have reached the end of job offers.");
      await Future.delayed(const Duration(seconds: 4));
      if (_isVoiceSystemEnabled) {
        _askInitialQuestion();
      }
    }
  }

  void _listenForJobCommand() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(onError: (error) {
        print("STT Initialization Error: ${error.errorMsg}");
      });

      if (!available) {
        await _flutterTts.speak("Speech recognition is not available.");
        return;
      }

      setState(() => _isListening = true);

      try {
        await _speechToText.listen(
          onResult: (result) async {
            String userResponse = result.recognizedWords.toLowerCase().trim();
            print("User Response: $userResponse");

            if (userResponse.isNotEmpty) {
              bool commandHandled = _handleJobReadingCommand(userResponse);
              if (!commandHandled) {
                await _flutterTts.speak("I didn't understand. Please try again.");
                await Future.delayed(const Duration(seconds: 7));
                _listenForJobCommand();
              }
            } else {
              await _flutterTts.speak("I didn't hear anything. Please say it again.");
              await Future.delayed(const Duration(seconds: 7));
              _listenForJobCommand();
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 12),
          listenOptions: stt.SpeechListenOptions(partialResults: false),
        );
      } catch (e) {
        print("Error starting STT: $e");
        await _flutterTts.speak("An unexpected error occurred. Please try again.");
      } finally {
        setState(() => _isListening = false);
      }
    }

    _speechToText.errorListener = (error) async {
      print("STT Error: ${error.errorMsg}");
      if (error.errorMsg.contains("error_no_match")) {
        await _flutterTts.speak("I couldn't understand. Please say it again.");
        await Future.delayed(const Duration(seconds: 15));
        _listenForJobCommand();
      } else {
        await _flutterTts.speak("There was an error. Please try again.");
      }
    };
  }

  void _stopTTSAndSTT() {
    if (_isListening) {
      _speechToText.stop();
      setState(() => _isListening = false);
    }
    _flutterTts.stop();
  }

  void _navigateToJobDetails() {
    if (_currentJobIndex < _filteredJobs.length) {
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => JobDetailPage(job: _filteredJobs[_currentJobIndex])));
    }
  }

  void _saveJobToBookmarks() async {
    if (_currentJobIndex < _filteredJobs.length) {
      await _flutterTts.speak("Job saved to bookmarks.");
      await Future.delayed(const Duration(seconds: 3));
      _currentJobIndex++;
      _readJobOffer(_currentJobIndex);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  void _searchJobs() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredJobs = _jobs;
      } else {
        _filteredJobs = _jobs.where((job) {
          return job.jobTitle
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
        }).toList();
      }
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredJobs = _jobs.where((job) {
        final matchesLocation = _selectedLocation == null ||
            (job.jobLocation.toLowerCase() == _selectedLocation!.toLowerCase());
        final matchesJobType = _selectedJobType == null ||
            (job.jobType.toLowerCase() == _selectedJobType!.toLowerCase());
        return matchesLocation && matchesJobType;
      }).toList();
    });
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF244855),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.0))),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Job Location', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                hint: const Text('Select Location', style: TextStyle(color: Colors.white)),
                dropdownColor: const Color(0xFF283E51),
                items: _locations.map((location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(location, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) { setState(() { _selectedLocation = value; }); },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16.0),
              const Text('Job Type', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                hint: const Text('Select Job Type', style: TextStyle(color: Colors.white)),
                dropdownColor: const Color(0xFF283E51),
                items: _jobTypes.map((jobType) {
                  return DropdownMenuItem<String>(
                    value: jobType,
                    child: Text(jobType, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) { setState(() { _selectedJobType = value; }); },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD76315),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: () { _applyFilters(); Navigator.pop(context); },
                  child: const Text('Apply Filters',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16.0),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedLocation = null;
                      _selectedJobType = null;
                      _filteredJobs = _jobs;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear Filters',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() { _selectedIndex = index; });

    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => JobSeekerHome(
                applicantName: '', isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => PartTimeJobsPage(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => BookmarksPage(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => ApplicantCVScreen(isVoiceSystemEnabled: _isVoiceSystemEnabled)));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF244855),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16.0),
                ),
                onChanged: (value) { _searchJobs(); },
              ),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFFFFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
              onPressed: () { _showFilterSheet(context); },
              child: const Icon(Icons.tune, color: Color(0xFF283E51)),
            ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF143850),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(7.0),
            child: Text(
              'Unlock your part-time potential!',
              style: TextStyle(
                color: Color(0xFFFFFFFF), fontSize: 18.0, fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _filteredJobs.isEmpty
                ? Center(
                    child: _searchController.text.isEmpty
                        ? const CircularProgressIndicator()
                        : Text(
                            'No results found for "${_searchController.text}".',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _filteredJobs.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => JobDetailPage(
                                      job: _filteredJobs[index])));
                            },
                            child: _filteredJobs[index],
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF283E51)),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Bookmarks'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFD76315),
          unselectedItemColor: const Color(0xFFD76315),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
