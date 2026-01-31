/// Crop care reminders with localized messages
class CropCareReminder {
  final String cropType; // e.g., 'cotton', 'rice', 'corn'
  final String reminderKey; // e.g., 'spray_pesticide', 'water_crop'
  final Map<String, String> messages; // Language -> message mapping

  CropCareReminder({
    required this.cropType,
    required this.reminderKey,
    required this.messages,
  });
}

/// Predefined crop care reminders
final List<CropCareReminder> cropCareReminders = [
  // Cotton reminders
  CropCareReminder(
    cropType: 'cotton',
    reminderKey: 'spray_pesticide',
    messages: {
      'en': 'Time to spray your cotton with pesticides to prevent pest damage!',
      'hi': 'आपकी कपास पर कीटनाशक का छिड़काव करने का समय है!',
      'te':
          'కీటలను నివారించడానికి మీ పత్తికి కీటకनాశకాలను చిమ్ముకోవడానికి సమయం!',
      'ta': 'உங்கள் பருத்திக்கு பூச்சிக்கொல்லி தெளிக்க வேண்டிய நேரம்!',
      'kn': 'ನಿಮ್ಮ ಹೊಟ್ಟನ ಮೇಲೆ ಕೀಟನಾಶಕವನ್ನು ಸಿಂಚನ ಮಾಡುವ ಸಮಯ!',
    },
  ),
  CropCareReminder(
    cropType: 'cotton',
    reminderKey: 'water_crop',
    messages: {
      'en':
          'Remember to water your cotton fields adequately for better growth!',
      'hi':
          'अपनी कपास के खेतों को बेहतर विकास के लिए पर्याप्त पानी देना याद रखें!',
      'te':
          'మెరుగైన పెరుగుదల కోసం మీ పత్తి పొలాలకు తగిన నీటిని ఇవ్వాలని గుర్తుంచుకోండి!',
      'ta':
          'உங்கள் பருத்தி வயல்களுக்கு சிறந்த வளர்ச்சிக்கு போதுமான நீர் கொடுக்க மறக்காதீர்கள்!',
      'kn':
          'ಉತ್ತಮ ಬೆಳವಣಿಗೆಗಾಗಿ ನಿಮ್ಮ ಹೊಟ್ಟನ ಹೊಲಗಳಿಗೆ ಸಾಕಷ್ಟು ನೀರು ಕೊಡುವುದನ್ನು ನೆನಪಿಡಿ!',
    },
  ),
  CropCareReminder(
    cropType: 'cotton',
    reminderKey: 'apply_fertilizer',
    messages: {
      'en': 'It\'s time to apply fertilizer to boost cotton yield!',
      'hi': 'कपास की पैदावार बढ़ाने के लिए खाद लगाने का समय है!',
      'te': 'కార్మిక ఉత్పాదన వృద్ధి చేయడానికి ఎరువులు వర్తించే సమయం!',
      'ta': 'பருத்தி விளைச்சலை அதிகரிக்க உரம் பயன்படுத்த வேண்டிய நேரம்!',
      'kn': 'ಹೊಟ್ಟನ ಬೆಳವಣಿಗೆ ಹೆಚ್ಚಿಸಲು ಸಾರಗಳನ್ನು ಅನ್ವಯಿಸುವ ಸಮಯ!',
    },
  ),

  // Rice reminders
  CropCareReminder(
    cropType: 'rice',
    reminderKey: 'check_water_level',
    messages: {
      'en': 'Check and maintain proper water level in your rice paddies!',
      'hi': 'अपने चावल के खेतों में उचित जल स्तर की जांच और रखरखाव करें!',
      'te':
          'మీ రైస్ పాడీలలో సరైన నీటి స్థాయిని తనిఖీ చేయండి మరియు నిర్వహించండి!',
      'ta':
          'உங்கள் நெல் வயல்களில் சரியான நீர் நிலையை சரிபார்க்கவும் மற்றும் பராமரிக்கவும்!',
      'kn':
          'ನಿಮ್ಮ ಅಕ್ಕಿ ಪ್ಯಾಡಿಗಳಲ್ಲಿ ಸರಿಯಾದ ನೀರಿನ ಸ್ತರವನ್ನು ಪರಿಶೀಲಿಸಿ ಮತ್ತು ನಿರ್ವಹಿಸಿ!',
    },
  ),
  CropCareReminder(
    cropType: 'rice',
    reminderKey: 'weed_control',
    messages: {
      'en': 'Time for weed control in your rice fields!',
      'hi': 'आपके चावल के खेतों में खरपतवार नियंत्रण का समय है!',
      'te': 'మీ రైస్ ఫీల్డ్‌లలో కండర నియంత్రణ సమయం!',
      'ta': 'உங்கள் நெல் வயல்களில் களைக்கொல்லி நிலை!',
      'kn': 'ನಿಮ್ಮ ಅಕ್ಕಿ ಹೊಲಗಳಲ್ಲಿ ಕಳೆ ನಿಯಂತ್ರಣ ಸಮಯ!',
    },
  ),

  // Corn reminders
  CropCareReminder(
    cropType: 'corn',
    reminderKey: 'check_for_pests',
    messages: {
      'en': 'Inspect your corn for pests and diseases regularly!',
      'hi': 'अपनी मकई की नियमित रूप से कीटों और बीमारियों के लिए जांच करें!',
      'te': 'మీ మకైకు క్రమం తప్పకుండా కీటలు మరియు వ్యాధుల కోసం తనిఖీ చేయండి!',
      'ta':
          'உங்கள் சோளத்தை வழக்கமாக பூச்சிகள் மற்றும் நோய்களுக்கு ஆய்வு செய்யுங்கள்!',
      'kn':
          'ನಿಮ್ಮ ಕಾರ್ನ್ ಅನ್ನು ನಿಯಮಿತವಾಗಿ ಕೀಟಗಳು ಮತ್ತು ರೋಗಗಳ ಸಾಲಿಕೆಗಳಿಗೆ ಪರಿಶೀಲಿಸಿ!',
    },
  ),

  // General reminders
  CropCareReminder(
    cropType: 'general',
    reminderKey: 'daily_inspection',
    messages: {
      'en': 'Don\'t forget to do a daily inspection of your crops!',
      'hi': 'अपनी फसलों का दैनिक निरीक्षण करना न भूलें!',
      'te': 'మీ పంటల యొక్క రోజువారీ తనిఖీ చేయడం మర్చిపోవద్దు!',
      'ta': 'உங்கள் பயிர்களை தினசரி ஆய்வு செய்ய மறக்காதீர்கள்!',
      'kn': 'ನಿಮ್ಮ ಸಸ್ಯಗಳನ್ನು ದೈನಿಕ ಪರಿಶೀಲನೆ ಮಾಡುವುದನ್ನು ಮರೆಯಬೇಡಿ!',
    },
  ),
];
