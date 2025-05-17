import 'package:flutter/material.dart';

class FlashcardView extends StatefulWidget {
  final String flashcardsText;

  const FlashcardView({Key? key, required this.flashcardsText}) : super(key: key);

  @override
  _FlashcardViewState createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  late List<Flashcard> _flashcards;
  int _currentIndex = 0;
  bool _showingFront = true;

  @override
  void initState() {
    super.initState();
    _parseFlashcards();
  }

  void _parseFlashcards() {
    _flashcards = [];

    // Split the text into lines
    final lines = widget.flashcardsText.split('\n');

    for (final line in lines) {
      if (line.trim().isNotEmpty) {
        // Split each line by tab to get term and definition
        final parts = line.split('\t');
        if (parts.length >= 2) {
          _flashcards.add(Flashcard(
            term: parts[0].trim(),
            definition: parts[1].trim(),
          ));
        }
      }
    }

    if (_flashcards.isEmpty) {
      // Fallback if parsing fails
      _flashcards.add(Flashcard(
        term: 'No flashcards available',
        definition: 'Please try regenerating the flashcards',
      ));
    }
  }

  void _nextCard() {
    setState(() {
      if (_currentIndex < _flashcards.length - 1) {
        _currentIndex++;
        _showingFront = true;
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _showingFront = true;
      }
    });
  }

  void _flipCard() {
    setState(() {
      _showingFront = !_showingFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
        actions: [
          Text('${_currentIndex + 1}/${_flashcards.length}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: Card(
                margin: EdgeInsets.all(16),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      _showingFront
                          ? _flashcards[_currentIndex].term
                          : _flashcards[_currentIndex].definition,
                      style: TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              _showingFront ? 'Tap to see definition' : 'Tap to see term',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0 ? _previousCard : null,
                  child: Icon(Icons.arrow_back),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _flipCard,
                  child: Icon(Icons.flip),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _currentIndex < _flashcards.length - 1 ? _nextCard : null,
                  child: Icon(Icons.arrow_forward),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Flashcard {
  final String term;
  final String definition;

  Flashcard({required this.term, required this.definition});
}