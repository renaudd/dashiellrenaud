import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import 'manor_screen.dart';

class IntroductionScreen extends StatefulWidget {
  const IntroductionScreen({super.key});

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  int _currentScene = 1;

  // Selections
  DeathCause? _deathCause;
  int _age = 25;
  GilesTrait _gilesTrait = GilesTrait.sage;
  LifeObjective _objective = LifeObjective.science;

  final TextEditingController _firstNameController = TextEditingController(
    text: "Alphonse",
  );
  final TextEditingController _lastNameController = TextEditingController(
    text: "Frankenstein",
  );
  final TextEditingController _estateNameController = TextEditingController(
    text: "Ingolstadt",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      body: Stack(
        children: [
          // Background Spitzweg Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg',
                fit: BoxFit.cover,
                color: Colors.black,
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 40.0,
              vertical: 60.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                Expanded(child: _buildSceneContent()),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'ANNO 1860',
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFC4B89B),
        fontSize: 12,
        letterSpacing: 4,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSceneContent() {
    switch (_currentScene) {
      case 1:
        return _scene1();
      case 2:
        return _scene2();
      case 3:
        return _scene3();
      case 4:
        return _scene4();
      case 5:
        return _scene5();
      case 6:
        return _scene6();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _scene1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText("Your parents have died. It was a..."),
        const SizedBox(height: 40),
        _optionButton(
          "TERRIBLE DISEASE.",
          () => _selectDeath(DeathCause.disease),
        ),
        _optionButton(
          "TRAIN CRASH.",
          () => _selectDeath(DeathCause.trainCrash),
        ),
        _optionButton(
          "MURDER-SUICIDE.",
          () => _selectDeath(DeathCause.murderSuicide),
        ),
        _optionButton(
          "MISUNDERSTANDING.",
          () => _selectDeath(DeathCause.misunderstanding),
        ),
      ],
    );
  }

  Widget _scene2() {
    String reaction = "";
    switch (_deathCause) {
      case DeathCause.disease:
        reaction =
            "The stench of ether still haunts the hallways of your memories.";
        break;
      case DeathCause.trainCrash:
        reaction = "The iron beast's failure was... explosive.";
        break;
      case DeathCause.murderSuicide:
        reaction = "A violent end for a violent lineage.";
        break;
      case DeathCause.misunderstanding:
        reaction = "A comedy of errors, ending in tragedy.";
        break;
      default:
        break;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText(reaction),
        const SizedBox(height: 20),
        _sceneText("Leaving you, Master..."),
        const SizedBox(height: 20),
        _inputField("FIRST NAME", _firstNameController),
        const SizedBox(height: 12),
        _inputField("LAST NAME", _lastNameController),
        const SizedBox(height: 12),
        _sceneText("as Junker of..."),
        const SizedBox(height: 12),
        _inputField("ESTATE NAME", _estateNameController),
      ],
    );
  }

  Widget _scene3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText("A terrible fate to befall a boy who is only..."),
        const SizedBox(height: 40),
        _optionButton(
          "15 YEARS OLD.",
          () => _selectAge(15),
          isSelected: _age == 15,
        ),
        _optionButton(
          "25 YEARS OLD.",
          () => _selectAge(25),
          isSelected: _age == 25,
        ),
        _optionButton(
          "35 YEARS OLD.",
          () => _selectAge(35),
          isSelected: _age == 35,
        ),
        _optionButton(
          "45 YEARS OLD.",
          () => _selectAge(45),
          isSelected: _age == 45,
        ),
      ],
    );
  }

  Widget _scene4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText(
          "In this time of great mourning, take comfort in the continued servitude of your everloyal butler, Flaubert Giles.",
        ),
        const SizedBox(height: 20),
        _sceneText("Giles was always really good at..."),
        const SizedBox(height: 40),
        _optionButton(
          "GIVING SAGE ADVICE.",
          () => _selectGiles(GilesTrait.sage),
          isSelected: _gilesTrait == GilesTrait.sage,
        ),
        _optionButton(
          "MAKING ENDS MEET.",
          () => _selectGiles(GilesTrait.endsMeet),
          isSelected: _gilesTrait == GilesTrait.endsMeet,
        ),
        _optionButton(
          "KEEPING HIS MOUTH SHUT.",
          () => _selectGiles(GilesTrait.silent),
          isSelected: _gilesTrait == GilesTrait.silent,
        ),
        _optionButton(
          "NOT SHUFFLING HIS FEET.",
          () => _selectGiles(GilesTrait.shuffle),
          isSelected: _gilesTrait == GilesTrait.shuffle,
        ),
      ],
    );
  }

  Widget _scene5() {
    String intro = _gilesTrait == GilesTrait.silent
        ? "Silence fills the room as you reflect. This is an opportunity for you to finally pursue your interest in..."
        : "Giles adjust his spectacles. 'This is an opportunity for you to finally pursue your interest in...'";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText(intro),
        const SizedBox(height: 40),
        _optionButton(
          "WOMEN.",
          () => _selectObjective(LifeObjective.women),
          isSelected: _objective == LifeObjective.women,
        ),
        _optionButton(
          "MONEY.",
          () => _selectObjective(LifeObjective.money),
          isSelected: _objective == LifeObjective.money,
        ),
        _optionButton(
          "FAME.",
          () => _selectObjective(LifeObjective.fame),
          isSelected: _objective == LifeObjective.fame,
        ),
        _optionButton(
          "SCIENCE.",
          () => _selectObjective(LifeObjective.science),
          isSelected: _objective == LifeObjective.science,
        ),
      ],
    );
  }

  Widget _scene6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneText("The manor stands silent, awaiting your command."),
        const SizedBox(height: 20),
        _sceneText("'First, this house really needs to be cleaned up.'"),
        const SizedBox(height: 40),
        Center(
          child: _optionButton(
            "BEGIN THE WORK",
            () => _finish(context),
            isSelected: true,
          ),
        ),
      ],
    );
  }

  Widget _sceneText(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: GoogleFonts.oldStandardTt(color: const Color(0xFFC4B89B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.playfairDisplay(
          color: Colors.white24,
          fontSize: 10,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white10),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC4B89B)),
        ),
      ),
    );
  }

  Widget _optionButton(
    String label,
    VoidCallback onTap, {
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? const Color(0xFFC4B89B) : Colors.white10,
            ),
            color: isSelected
                ? const Color(0xFFC4B89B).withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Text(
            label,
            style: GoogleFonts.playfairDisplay(
              color: isSelected ? const Color(0xFFE5D5B0) : Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentScene > 1)
          TextButton(
            onPressed: () => setState(() => _currentScene--),
            child: Text(
              "BACK",
              style: GoogleFonts.playfairDisplay(color: Colors.white24),
            ),
          )
        else
          const SizedBox.shrink(),
        if (_currentScene < 6 &&
            _currentScene != 1) // Scene 1 requires selection to advance
          TextButton(
            onPressed: () => setState(() => _currentScene++),
            child: Text(
              "NEXT",
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFC4B89B),
              ),
            ),
          ),
      ],
    );
  }

  void _selectDeath(DeathCause cause) {
    setState(() {
      _deathCause = cause;
      _currentScene = 2;
    });
  }

  void _selectAge(int age) {
    setState(() {
      _age = age;
      _currentScene = 4;
    });
  }

  void _selectGiles(GilesTrait trait) {
    setState(() {
      _gilesTrait = trait;
      _currentScene = 5;
    });
  }

  void _selectObjective(LifeObjective objective) {
    setState(() {
      _objective = objective;
      _currentScene = 6;
    });
  }

  void _finish(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);
    state.initializeNewGame(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      estateName: _estateNameController.text,
      deathCause: _deathCause!,
      age: _age,
      gilesTrait: _gilesTrait,
      objective: _objective,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ManorScreen()),
      (route) => false,
    );
  }
}
