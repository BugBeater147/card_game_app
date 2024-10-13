import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => GameProvider(),
      child: CardMatchingGame(),
    ),
  );
}

class CardMatchingGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Card Matching Game'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4x4 grid
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: gameProvider.cards.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    gameProvider.flipCard(index, context);
                  },
                  child: CardWidget(card: gameProvider.cards[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                gameProvider
                    .restartGame(); // Call the method to restart the game
              },
              child: Text('Restart'),
            ),
          ),
        ],
      ),
    );
  }
}

class CardWidget extends StatefulWidget {
  final CardModel card;

  const CardWidget({required this.card});

  @override
  _CardWidgetState createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.card.isFaceUp) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animation,
      child: widget.card.isFaceUp
          ? Image.network(widget.card.frontDesign) // Show front if face-up
          : Image.network(widget.card.backDesign), // Show back if face-down
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class GameProvider extends ChangeNotifier {
  List<CardModel> cards = [];
  List<int> flippedCardIndices = []; // Track two flipped cards

  GameProvider() {
    _initializeCards();
  }

  // Initialize the cards with shuffled order
  void _initializeCards() {
    String cardBackUrl =
        'https://mir-s3-cdn-cf.behance.net/project_modules/max_1200/a2b99b78814263.5caf8da69d88a.png';
    List<String> cardFrontUrls = [
      'https://pbs.twimg.com/media/ElEXK8_XUAEEtuU.jpg',
      'https://pbs.twimg.com/media/F3y-7dRXQAAWiMN.jpg',
      'https://pbs.twimg.com/media/GU-G9NFWEAAj1lV.jpg:large',
      'https://pbs.twimg.com/media/GRk-fI4aUAE_hGv?format=jpg&name=4096x4096',
      'https://www.reuters.com/resizer/v2/https%3A%2F%2Fcloudfront-us-east-2.images.arcpublishing.com%2Freuters%2F5Y5I76LGM5LLRNSD4MKE4GIYKM.jpg?auth=9858c930a04486f42ff304af758a5d6ddb8580ee74a0cc39657e2d8050a7e9dc&height=2400&width=1920&quality=80&smart=true',
      'https://i.pinimg.com/736x/e6/56/c0/e656c075e0aa953b6433441da40aea9d.jpg',
      'https://www.thesun.co.uk/wp-content/uploads/2019/05/NINTCHDBPICT000493066512-e1558888704696.jpg?strip=all&w=630',
    ];

    // Duplicate each image to create pairs, then shuffle the list
    List<String> allCards = [...cardFrontUrls, ...cardFrontUrls];
    allCards.shuffle(); // Shuffle the cards for random placement

    // Create card models with the shuffled URLs
    cards = allCards.map((frontUrl) {
      return CardModel(
        frontDesign: frontUrl,
        backDesign: cardBackUrl,
      );
    }).toList();

    notifyListeners(); // Notify the UI of the card updates
  }

  // Method to handle flipping cards
  void flipCard(int index, BuildContext context) {
    if (cards[index].isFaceUp || flippedCardIndices.length == 2) return;

    // Flip the card
    cards[index].isFaceUp = true;
    flippedCardIndices.add(index);
    notifyListeners();

    // Check if two cards are flipped
    if (flippedCardIndices.length == 2) {
      int firstIndex = flippedCardIndices[0];
      int secondIndex = flippedCardIndices[1];

      if (cards[firstIndex].frontDesign == cards[secondIndex].frontDesign) {
        // Cards match
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Matched!'),
          duration: Duration(seconds: 1),
        ));
        flippedCardIndices.clear(); // Clear matched cards from the list
      } else {
        // Cards don't match, flip them back after 1 second
        Future.delayed(Duration(seconds: 1), () {
          cards[firstIndex].isFaceUp = false;
          cards[secondIndex].isFaceUp = false;
          flippedCardIndices.clear(); // Clear flipped cards list
          notifyListeners(); // Notify the UI to update
        });
      }
    }
  }

  // Restart game by reshuffling and resetting all cards to face-down
  void restartGame() {
    // Reset and reshuffle all cards
    _initializeCards();
    // Ensure all cards are face-down
    for (var card in cards) {
      card.isFaceUp = false;
    }
    flippedCardIndices.clear(); // Clear any flipped card states
    notifyListeners(); // Notify the UI of the updates
  }
}

class CardModel {
  String frontDesign; // Holds a URL to the front image
  String backDesign; // Holds a URL for the back of the card
  bool isFaceUp;

  CardModel({
    required this.frontDesign,
    required this.backDesign,
    this.isFaceUp = false,
  });
}
