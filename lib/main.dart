import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // This is the file the CLI just made!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}